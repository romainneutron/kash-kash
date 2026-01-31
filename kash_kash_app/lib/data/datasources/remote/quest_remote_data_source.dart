import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/data/datasources/remote/api/api_client.dart';
import 'package:kash_kash_app/data/models/quest_model.dart';

/// API endpoint paths for quest operations.
abstract class QuestEndpoints {
  static const String quests = '/api/quests';
  static const String nearby = '/api/quests/nearby';
  static String questById(String id) => '/api/quests/$id';
  static String publish(String id) => '/api/quests/$id/publish';
  static String unpublish(String id) => '/api/quests/$id/unpublish';
}

/// Remote data source for quest operations.
class QuestRemoteDataSource {
  final ApiClient _apiClient;

  QuestRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Fetch all published quests.
  Future<List<QuestModel>> getPublishedQuests() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>(QuestEndpoints.quests);
    final items = _extractListFromResponse(response.data);
    return items
        .map((json) => QuestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch quests near a specific location.
  ///
  /// Throws [ArgumentError] if coordinates are invalid:
  /// - latitude must be between -90 and 90
  /// - longitude must be between -180 and 180
  /// - radiusKm must be positive
  Future<List<QuestModel>> getNearbyQuests({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    // Validate inputs
    if (lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'lat', 'Latitude must be between -90 and 90');
    }
    if (lng < -180 || lng > 180) {
      throw ArgumentError.value(lng, 'lng', 'Longitude must be between -180 and 180');
    }
    if (radiusKm <= 0) {
      throw ArgumentError.value(radiusKm, 'radiusKm', 'Radius must be positive');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      QuestEndpoints.nearby,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
      },
    );
    final items = _extractListFromResponse(response.data, keys: _nearbyListKeys);
    return items
        .map((json) => QuestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single quest by ID.
  Future<QuestModel> getQuestById(String id) async {
    final response =
        await _apiClient.get<Map<String, dynamic>>(QuestEndpoints.questById(id));
    return QuestModel.fromJson(_requireData(response.data));
  }

  /// Create a new quest (admin only).
  Future<QuestModel> createQuest(QuestModel quest) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      QuestEndpoints.quests,
      data: quest.toJson(),
    );
    return QuestModel.fromJson(_requireData(response.data));
  }

  /// Update an existing quest (admin only).
  Future<QuestModel> updateQuest(QuestModel quest) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      QuestEndpoints.questById(quest.id),
      data: quest.toJson(),
    );
    return QuestModel.fromJson(_requireData(response.data));
  }

  /// Delete a quest (admin only).
  Future<void> deleteQuest(String id) async {
    await _apiClient.delete(QuestEndpoints.questById(id));
  }

  /// Publish a quest (admin only).
  Future<QuestModel> publishQuest(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      QuestEndpoints.publish(id),
    );
    return QuestModel.fromJson(_requireData(response.data));
  }

  /// Unpublish a quest (admin only).
  Future<QuestModel> unpublishQuest(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      QuestEndpoints.unpublish(id),
    );
    return QuestModel.fromJson(_requireData(response.data));
  }

  /// Require non-null response data or throw.
  Map<String, dynamic> _requireData(Map<String, dynamic>? data) {
    if (data == null) {
      throw const ServerException('Empty response from API');
    }
    return data;
  }

  /// Keys to try for standard API Platform responses.
  static const _defaultListKeys = ['hydra:member', 'data'];

  /// Keys to try for nearby endpoint responses (includes 'quests' key).
  static const _nearbyListKeys = ['hydra:member', 'data', 'quests'];

  /// Extract list from API response by trying keys in order.
  List<dynamic> _extractListFromResponse(
    Map<String, dynamic>? data, {
    List<String> keys = _defaultListKeys,
  }) {
    final requiredData = _requireData(data);
    for (final key in keys) {
      final value = requiredData[key];
      if (value != null) return value as List<dynamic>;
    }
    return [];
  }
}
