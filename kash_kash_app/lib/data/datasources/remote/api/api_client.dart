import 'package:dio/dio.dart';
import 'package:kash_kash_app/data/datasources/remote/api/auth_interceptor.dart';
import 'package:kash_kash_app/infrastructure/storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage _secureStorage;

  static const String _defaultBaseUrl = 'https://main-bvxea6i-zbl4tfxlbq4ss.eu-5.platformsh.site';

  ApiClient({
    required SecureStorage secureStorage,
    String? baseUrl,
  }) : _secureStorage = secureStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? const String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        storage: _secureStorage,
        dio: dio,
      ),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
