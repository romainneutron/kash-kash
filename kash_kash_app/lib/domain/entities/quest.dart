/// Quest difficulty levels
enum QuestDifficulty { easy, medium, hard, expert }

/// Location types for quests
enum LocationType { city, forest, park, water, mountain, indoor }

/// Quest entity representing a geocaching location
class Quest {
  final String id;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String createdBy;
  final bool published;
  final QuestDifficulty? difficulty;
  final LocationType? locationType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  const Quest({
    required this.id,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 3.0,
    required this.createdBy,
    this.published = false,
    this.difficulty,
    this.locationType,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? createdBy,
    bool? published,
    QuestDifficulty? difficulty,
    LocationType? locationType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdBy: createdBy ?? this.createdBy,
      published: published ?? this.published,
      difficulty: difficulty ?? this.difficulty,
      locationType: locationType ?? this.locationType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
