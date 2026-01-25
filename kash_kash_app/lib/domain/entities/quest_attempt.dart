/// Attempt status
enum AttemptStatus { inProgress, completed, abandoned }

/// Quest attempt entity representing a user's gameplay session
class QuestAttempt {
  final String id;
  final String questId;
  final String userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? abandonedAt;
  final AttemptStatus status;
  final int? durationSeconds;
  final double? distanceWalked;
  final bool synced;

  const QuestAttempt({
    required this.id,
    required this.questId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    this.abandonedAt,
    required this.status,
    this.durationSeconds,
    this.distanceWalked,
    this.synced = false,
  });

  bool get isComplete => status == AttemptStatus.completed;
  bool get isAbandoned => status == AttemptStatus.abandoned;
  bool get isInProgress => status == AttemptStatus.inProgress;

  QuestAttempt copyWith({
    String? id,
    String? questId,
    String? userId,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? abandonedAt,
    AttemptStatus? status,
    int? durationSeconds,
    double? distanceWalked,
    bool? synced,
  }) {
    return QuestAttempt(
      id: id ?? this.id,
      questId: questId ?? this.questId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      abandonedAt: abandonedAt ?? this.abandonedAt,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceWalked: distanceWalked ?? this.distanceWalked,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestAttempt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
