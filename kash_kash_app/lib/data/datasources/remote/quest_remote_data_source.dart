import 'package:kash_kash_app/data/datasources/remote/api/api_client.dart';
import 'package:kash_kash_app/data/models/quest_model.dart';

/// Remote data source for quest operations.
class QuestRemoteDataSource {
  final ApiClient _apiClient;

  QuestRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Fetch all published quests.
  Future<List<QuestModel>> getPublishedQuests() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/api/quests');

    // Handle API Platform's hydra response format
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from API');
    }
    final List<dynamic> items = data['hydra:member'] ?? data['data'] ?? [];

    return items
        .map((json) => QuestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch quests near a specific location.
  ///
  /// [lat], [lng] - User's current coordinates
  /// [radiusKm] - Search radius in kilometers
  Future<List<QuestModel>> getNearbyQuests({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/quests/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
      },
    );

    // Handle different API response formats
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from API');
    }
    final List<dynamic> items =
        data['hydra:member'] ?? data['data'] ?? data['quests'] ?? [];

    return items
        .map((json) => QuestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single quest by ID.
  Future<QuestModel> getQuestById(String id) async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/api/quests/$id');
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from API');
    }
    return QuestModel.fromJson(data);
  }

  /// Create a new quest (admin only).
  Future<QuestModel> createQuest(QuestModel quest) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/quests',
      data: quest.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from API');
    }
    return QuestModel.fromJson(data);
  }

  /// Update an existing quest (admin only).
  Future<QuestModel> updateQuest(QuestModel quest) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/quests/${quest.id}',
      data: quest.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from API');
    }
    return QuestModel.fromJson(data);
  }

  /// Delete a quest (admin only).
  Future<void> deleteQuest(String id) async {
    await _apiClient.delete('/api/quests/$id');
  }

  /// Publish a quest (admin only).
  Future<QuestModel> publishQuest(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/quests/$id/publish',
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from API');
    }
    return QuestModel.fromJson(data);
  }

  /// Unpublish a quest (admin only).
  Future<QuestModel> unpublishQuest(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/quests/$id/unpublish',
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from API');
    }
    return QuestModel.fromJson(data);
  }
}
