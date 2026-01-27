import 'package:dio/dio.dart';
import 'package:kash_kash_app/data/datasources/remote/api/api_client.dart';
import 'package:kash_kash_app/data/models/auth_result.dart';
import 'package:kash_kash_app/data/models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(response.data!);
  }

  Future<AuthResult> refreshToken(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/token/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    final data = response.data!;
    return AuthResult(
      accessToken: data['token'] as String,
      refreshToken: data['refresh_token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Ignore errors on logout - we clear local state anyway
    }
  }

  String getGoogleAuthUrl() {
    return '${_apiClient.dio.options.baseUrl}/auth/google';
  }
}
