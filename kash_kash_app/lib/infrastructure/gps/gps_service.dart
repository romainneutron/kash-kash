import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/errors/failures.dart';

/// Result type for location permission checks.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Service wrapper for GPS operations with permission handling.
class GpsService {
  /// Default cache duration for position data.
  static const Duration defaultCacheTtl = Duration(seconds: 30);

  /// Cached position and timestamp.
  Position? _cachedPosition;
  DateTime? _cacheTimestamp;

  /// In-flight position fetch to prevent concurrent GPS requests.
  Completer<Either<Failure, Position>>? _pendingFetch;

  /// Cache TTL (configurable for testing).
  final Duration cacheTtl;

  GpsService({this.cacheTtl = defaultCacheTtl});

  /// Clear the position cache.
  void clearCache() {
    _cachedPosition = null;
    _cacheTimestamp = null;
  }

  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status.
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  /// Request location permission from the user.
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  /// Check if permission has been granted.
  Future<bool> hasPermission() async {
    final status = await checkPermissionStatus();
    return status == LocationPermissionStatus.granted;
  }

  /// Get current position.
  ///
  /// Returns cached position if available and valid, otherwise fetches fresh.
  /// Set [forceRefresh] to true to bypass the cache.
  ///
  /// Uses a Completer to prevent concurrent GPS requests, which would waste
  /// battery. If a fetch is already in progress, callers wait for that result.
  ///
  /// Returns a [LocationFailure] if permission is denied or location
  /// services are disabled.
  Future<Either<Failure, Position>> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeout,
    bool forceRefresh = false,
  }) async {
    // Return cached position if valid and not forcing refresh
    // Copy values atomically to prevent race condition with clearCache()
    if (!forceRefresh) {
      final cached = _cachedPosition;
      final timestamp = _cacheTimestamp;
      if (cached != null &&
          timestamp != null &&
          DateTime.now().difference(timestamp) < cacheTtl) {
        return Right(cached);
      }
    }

    // If a fetch is already in progress, wait for it
    if (_pendingFetch != null) {
      return _pendingFetch!.future;
    }

    // Start a new fetch
    _pendingFetch = Completer<Either<Failure, Position>>();

    try {
      final result = await _doGetCurrentPosition(accuracy, timeout);
      _pendingFetch!.complete(result);
      return result;
    } catch (e) {
      final failure = Left<Failure, Position>(
        LocationFailure('Failed to get location: $e'),
      );
      _pendingFetch!.complete(failure);
      return failure;
    } finally {
      _pendingFetch = null;
    }
  }

  Future<Either<Failure, Position>> _doGetCurrentPosition(
    LocationAccuracy accuracy,
    Duration? timeout,
  ) async {
    try {
      final hasLocationPermission = await hasPermission();
      if (!hasLocationPermission) {
        final status = await requestPermission();
        if (status != LocationPermissionStatus.granted) {
          return Left(LocationFailure(_permissionMessage(status)));
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );

      // Update cache
      _cachedPosition = position;
      _cacheTimestamp = DateTime.now();

      return Right(position);
    } on LocationServiceDisabledException {
      return const Left(LocationFailure('Location services are disabled'));
    } on PermissionDeniedException catch (e) {
      return Left(LocationFailure('Permission denied: ${e.message}'));
    }
  }

  /// Stream position updates.
  ///
  /// [accuracy] - Desired accuracy level.
  /// [distanceFilter] - Minimum distance (in meters) between updates.
  Stream<Position> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Stream position updates with error handling.
  ///
  /// Wraps the raw stream with Either to handle location errors.
  Stream<Either<Failure, Position>> watchPositionSafe({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async* {
    final hasLocationPermission = await hasPermission();
    if (!hasLocationPermission) {
      final status = await requestPermission();
      if (status != LocationPermissionStatus.granted) {
        yield Left(LocationFailure(_permissionMessage(status)));
        return;
      }
    }

    try {
      await for (final position in Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      )) {
        yield Right(position);
      }
    } on LocationServiceDisabledException {
      yield const Left(LocationFailure('Location services were disabled'));
    } on PermissionDeniedException catch (e) {
      yield Left(LocationFailure('Permission denied: ${e.message}'));
    } catch (e) {
      yield Left(LocationFailure('Location stream error: $e'));
    }
  }

  /// Calculate distance between two positions in meters.
  double distanceBetween(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Open location settings on the device.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Open app settings for permission management.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }

  String _permissionMessage(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.denied:
        return 'Location permission denied';
      case LocationPermissionStatus.deniedForever:
        return 'Location permission permanently denied. Please enable in settings.';
      case LocationPermissionStatus.serviceDisabled:
        return 'Location services are disabled';
      case LocationPermissionStatus.granted:
        return 'Permission granted';
    }
  }
}
