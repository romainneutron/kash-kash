import 'package:kash_kash_app/data/datasources/local/database.dart' as db;
import 'package:kash_kash_app/domain/entities/quest.dart' as domain;

/// Data transfer model for Quest.
///
/// Handles serialization between API JSON, Drift database, and domain entity.
class QuestModel {
  final String id;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String createdBy;
  final bool published;
  final String? difficulty;
  final String? locationType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  /// Transient field - calculated distance from user's location (from API).
  final double? distanceKm;

  const QuestModel({
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
    this.distanceKm,
  });

  /// Create from API JSON response.
  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 3.0,
      createdBy: json['created_by'] as String,
      published: json['published'] as bool? ?? false,
      difficulty: json['difficulty'] as String?,
      locationType: json['location_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  /// Convert to API JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'created_by': createdBy,
      'published': published,
      'difficulty': difficulty,
      'location_type': locationType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (syncedAt != null) 'synced_at': syncedAt!.toIso8601String(),
      if (distanceKm != null) 'distance_km': distanceKm,
    };
  }

  /// Convert to domain Quest entity.
  domain.Quest toDomain() {
    return domain.Quest(
      id: id,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      createdBy: createdBy,
      published: published,
      difficulty: _parseDifficulty(difficulty),
      locationType: _parseLocationType(locationType),
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncedAt: syncedAt,
    );
  }

  /// Create from domain Quest entity.
  factory QuestModel.fromDomain(domain.Quest quest) {
    return QuestModel(
      id: quest.id,
      title: quest.title,
      description: quest.description,
      latitude: quest.latitude,
      longitude: quest.longitude,
      radiusMeters: quest.radiusMeters,
      createdBy: quest.createdBy,
      published: quest.published,
      difficulty: quest.difficulty?.name,
      locationType: quest.locationType?.name,
      createdAt: quest.createdAt,
      updatedAt: quest.updatedAt,
      syncedAt: quest.syncedAt,
    );
  }

  /// Convert to Drift Quest data class.
  db.Quest toDrift() {
    return db.Quest(
      id: id,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      createdBy: createdBy,
      published: published,
      difficulty: _parseDriftDifficulty(difficulty),
      locationType: _parseDriftLocationType(locationType),
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncedAt: syncedAt,
    );
  }

  /// Create from Drift Quest data class.
  factory QuestModel.fromDrift(db.Quest quest) {
    return QuestModel(
      id: quest.id,
      title: quest.title,
      description: quest.description,
      latitude: quest.latitude,
      longitude: quest.longitude,
      radiusMeters: quest.radiusMeters,
      createdBy: quest.createdBy,
      published: quest.published,
      difficulty: quest.difficulty?.name,
      locationType: quest.locationType?.name,
      createdAt: quest.createdAt,
      updatedAt: quest.updatedAt,
      syncedAt: quest.syncedAt,
    );
  }

  static domain.QuestDifficulty? _parseDifficulty(String? value) {
    if (value == null) return null;
    return domain.QuestDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => domain.QuestDifficulty.easy,
    );
  }

  static domain.LocationType? _parseLocationType(String? value) {
    if (value == null) return null;
    return domain.LocationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => domain.LocationType.city,
    );
  }

  static db.QuestDifficulty? _parseDriftDifficulty(String? value) {
    if (value == null) return null;
    return db.QuestDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => db.QuestDifficulty.easy,
    );
  }

  static db.LocationType? _parseDriftLocationType(String? value) {
    if (value == null) return null;
    return db.LocationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => db.LocationType.city,
    );
  }

  QuestModel copyWith({
    String? id,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? createdBy,
    bool? published,
    String? difficulty,
    String? locationType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    double? distanceKm,
  }) {
    return QuestModel(
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
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
