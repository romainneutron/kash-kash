import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Privacy-first analytics service using Aptabase
///
/// Tracks product analytics without collecting any user identifiers (PII).
/// All events are anonymous and privacy-compliant by design.
class AnalyticsService {
  static bool _initialized = false;

  /// Initialize Aptabase SDK
  static Future<void> init({required String appKey}) async {
    if (_initialized || appKey.isEmpty) {
      if (kDebugMode && appKey.isEmpty) {
        debugPrint('AnalyticsService: No Aptabase key provided, analytics disabled');
      }
      return;
    }

    await Aptabase.init(appKey);
    _initialized = true;

    if (kDebugMode) {
      debugPrint('AnalyticsService: Initialized successfully');
    }
  }

  /// Track quest started event
  static void questStarted({required String questId}) {
    _trackEvent('quest_started', {
      'quest_id': questId,
    });
  }

  /// Track quest completed successfully
  static void questCompleted({
    required String questId,
    required int durationSeconds,
    required double distanceWalked,
  }) {
    _trackEvent('quest_completed', {
      'quest_id': questId,
      'duration_seconds': durationSeconds,
      'distance_meters': distanceWalked.round(),
    });
  }

  /// Track quest abandoned
  static void questAbandoned({
    required String questId,
    required int durationSeconds,
  }) {
    _trackEvent('quest_abandoned', {
      'quest_id': questId,
      'duration_seconds': durationSeconds,
    });
  }

  /// Track screen view (optional)
  static void screenView(String screenName) {
    _trackEvent('screen_view', {
      'screen': screenName,
    });
  }

  /// Track app opened
  static void appOpened() {
    _trackEvent('app_opened', {});
  }

  /// Generic event tracking (internal)
  static void _trackEvent(String eventName, Map<String, dynamic> properties) {
    if (!_initialized) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Would track $eventName: $properties');
      }
      return;
    }

    Aptabase.instance.trackEvent(eventName, properties);

    if (kDebugMode) {
      debugPrint('AnalyticsService: Tracked $eventName: $properties');
    }
  }
}
