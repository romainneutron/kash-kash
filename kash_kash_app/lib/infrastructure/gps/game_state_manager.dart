import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/quest.dart';
import '../../presentation/widgets/game_background.dart';
import 'direction_detector.dart';
import 'gps_service.dart';
import 'movement_detector.dart';

/// Central state manager orchestrating all gameplay logic.
///
/// Manages GPS tracking, movement detection, direction detection, and
/// emits gameplay state changes. Detects win condition when player
/// reaches target within radius.
class GameStateManager {
  /// The quest being played.
  final Quest quest;

  /// GPS service for position updates.
  final GpsService _gpsService;

  /// Movement detector for stationary/moving state.
  final MovementDetector _movementDetector;

  /// Direction detector for closer/farther state.
  late final DirectionDetector _directionDetector;

  /// Stream controller for gameplay state changes.
  final _stateController = StreamController<GameplayState>.broadcast();

  /// GPS position subscription.
  StreamSubscription<Position>? _positionSubscription;

  /// Current gameplay state.
  GameplayState _currentState = GameplayState.initializing;

  /// Current GPS position.
  Position? _currentPosition;

  /// Whether the manager has been disposed.
  bool _disposed = false;

  /// Creates a GameStateManager for the given quest.
  GameStateManager({
    required this.quest,
    required GpsService gpsService,
    MovementDetector? movementDetector,
  })  : _gpsService = gpsService,
        _movementDetector = movementDetector ?? MovementDetector() {
    _directionDetector = DirectionDetector(
      targetLat: quest.latitude,
      targetLng: quest.longitude,
    );
  }

  /// Stream of gameplay state changes.
  Stream<GameplayState> get stateStream => _stateController.stream;

  /// Current gameplay state.
  GameplayState get currentState => _currentState;

  /// Current GPS position, if available.
  Position? get currentPosition => _currentPosition;

  /// Current distance to target in meters.
  double get distanceToTarget => _directionDetector.currentDistance;

  /// Whether the manager has been disposed.
  bool get isDisposed => _disposed;

  /// Start GPS tracking and gameplay.
  void start() {
    if (_disposed) return;

    _positionSubscription = _gpsService
        .watchPosition(
      distanceFilter: 1, // Update every 1 meter
    )
        .listen(
      _onPositionUpdate,
      onError: _onError,
    );
  }

  /// Handle position update from GPS.
  void _onPositionUpdate(Position position) {
    if (_disposed) return;

    _currentPosition = position;

    // Always update direction detector to track distance
    final direction = _directionDetector.detect(
      position.latitude,
      position.longitude,
    );

    // Check win condition first
    // If GPS accuracy is poor, expand effective radius to prevent impossible wins
    // (e.g., 10m accuracy means we can't reliably detect 3m radius)
    final effectiveRadius = max(quest.radiusMeters, position.accuracy * 0.8);
    final distance = _directionDetector.currentDistance;

    if (distance <= effectiveRadius) {
      _updateState(GameplayState.won);
      return;
    }

    // Check movement
    final movement = _movementDetector.detect(position.speed);
    if (movement == MovementState.stationary) {
      _updateState(GameplayState.stationary);
      return;
    }

    // Update state based on direction
    switch (direction) {
      case DirectionState.gettingCloser:
        _updateState(GameplayState.gettingCloser);
      case DirectionState.gettingFarther:
        _updateState(GameplayState.gettingFarther);
      case DirectionState.noChange:
        // Keep previous state or default to stationary
        if (_currentState == GameplayState.initializing) {
          _updateState(GameplayState.stationary);
        }
    }
  }

  /// Handle GPS errors.
  void _onError(Object error, [StackTrace? stackTrace]) {
    if (_disposed) return;
    _updateState(GameplayState.error);
  }

  /// Update state and emit to stream.
  void _updateState(GameplayState newState) {
    if (_disposed) return;
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
    }
  }

  /// Check if player has won.
  bool get hasWon => _currentState == GameplayState.won;

  /// Check if player is within a given distance of target.
  bool isWithinDistance(double meters) {
    return _directionDetector.isWithinRadius(meters);
  }

  /// Reset the detectors (useful when restarting).
  void reset() {
    _movementDetector.reset();
    _directionDetector.reset();
    _currentState = GameplayState.initializing;
    _currentPosition = null;
  }

  /// Stop GPS tracking and clean up resources.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await _stateController.close();
  }
}
