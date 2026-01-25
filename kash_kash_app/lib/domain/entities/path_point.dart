/// Path point entity representing a GPS coordinate during gameplay
class PathPoint {
  final String id;
  final String attemptId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double speed;
  final bool synced;

  const PathPoint({
    required this.id,
    required this.attemptId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    required this.speed,
    this.synced = false,
  });

  PathPoint copyWith({
    String? id,
    String? attemptId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? accuracy,
    double? speed,
    bool? synced,
  }) {
    return PathPoint(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PathPoint && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
