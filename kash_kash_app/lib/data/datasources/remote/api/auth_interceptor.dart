import 'package:dio/dio.dart';
import 'package:kash_kash_app/infrastructure/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _pendingRequests = [];

  AuthInterceptor({
    required SecureStorage storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry refresh token requests
    if (err.requestOptions.path.contains('/auth/token/refresh')) {
      await _storage.clearTokens();
      return handler.next(err);
    }

    // Queue request if already refreshing
    if (_isRefreshing) {
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry original request
        final response = await _retryRequest(err.requestOptions);
        handler.resolve(response);

        // Process pending requests
        await _processPendingRequests();
      } else {
        handler.next(err);
        _rejectPendingRequests(err);
      }
    } catch (e) {
      handler.next(err);
      _rejectPendingRequests(err);
    } finally {
      _isRefreshing = false;
    }
  }

  bool _isPublicEndpoint(String path) {
    return path.startsWith('/auth/google') ||
        path.startsWith('/auth/token/refresh');
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/token/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // Remove auth header
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        await _storage.saveTokens(
          accessToken: data['token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        return true;
      }
    } catch (e) {
      await _storage.clearTokens();
    }
    return false;
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = await _storage.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _processPendingRequests() async {
    final requests = List.of(_pendingRequests);
    _pendingRequests.clear();

    for (final request in requests) {
      try {
        final response = await _retryRequest(request.options);
        request.handler.resolve(response);
      } catch (e) {
        request.handler.reject(
          DioException(requestOptions: request.options, error: e),
        );
      }
    }
  }

  void _rejectPendingRequests(DioException err) {
    for (final request in _pendingRequests) {
      request.handler.reject(
        DioException(requestOptions: request.options, error: err.error),
      );
    }
    _pendingRequests.clear();
  }
}
