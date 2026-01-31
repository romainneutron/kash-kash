import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:kash_kash_app/data/datasources/remote/api/auth_interceptor.dart';

import '../../../../../helpers/mocks.dart';

// Custom mock request handler for testing
class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late MockSecureStorage mockStorage;
  late MockDio mockDio;
  late AuthInterceptor interceptor;
  late MockRequestInterceptorHandler mockRequestHandler;
  late MockErrorInterceptorHandler mockErrorHandler;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(DioException(requestOptions: RequestOptions(path: '')));
    registerFallbackValue(Response(requestOptions: RequestOptions(path: '')));
  });

  setUp(() {
    mockStorage = MockSecureStorage();
    mockDio = MockDio();
    mockRequestHandler = MockRequestInterceptorHandler();
    mockErrorHandler = MockErrorInterceptorHandler();
    interceptor = AuthInterceptor(
      storage: mockStorage,
      dio: mockDio,
    );
  });

  group('AuthInterceptor', () {
    group('onRequest', () {
      test('should add Authorization header when token exists', () async {
        when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => 'valid-token');

        final options = RequestOptions(path: '/api/quests');

        await interceptor.onRequest(options, mockRequestHandler);

        verify(() => mockRequestHandler.next(any(that: predicate<RequestOptions>(
          (o) => o.headers['Authorization'] == 'Bearer valid-token',
        )))).called(1);
      });

      test('should not add header when no token', () async {
        when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => null);

        final options = RequestOptions(path: '/api/quests');

        await interceptor.onRequest(options, mockRequestHandler);

        verify(() => mockRequestHandler.next(any(that: predicate<RequestOptions>(
          (o) => o.headers['Authorization'] == null,
        )))).called(1);
      });

      test('should not add header when token is empty', () async {
        when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => '');

        final options = RequestOptions(path: '/api/quests');

        await interceptor.onRequest(options, mockRequestHandler);

        verify(() => mockRequestHandler.next(any(that: predicate<RequestOptions>(
          (o) => o.headers['Authorization'] == null,
        )))).called(1);
      });

      test('should skip auth for /auth/google endpoint', () async {
        final options = RequestOptions(path: '/auth/google');

        await interceptor.onRequest(options, mockRequestHandler);

        verify(() => mockRequestHandler.next(options)).called(1);
        verifyNever(() => mockStorage.getAccessToken());
      });

      test('should skip auth for /auth/token/refresh endpoint', () async {
        final options = RequestOptions(path: '/auth/token/refresh');

        await interceptor.onRequest(options, mockRequestHandler);

        verify(() => mockRequestHandler.next(options)).called(1);
        verifyNever(() => mockStorage.getAccessToken());
      });
    });

    group('onError', () {
      test('should pass through non-401 errors', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/quests'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/quests'),
          ),
        );

        await interceptor.onError(error, mockErrorHandler);

        verify(() => mockErrorHandler.next(error)).called(1);
      });

      test('should clear tokens and pass through when refresh token request fails', () async {
        when(() => mockStorage.clearTokens())
          .thenAnswer((_) async {});

        final error = DioException(
          requestOptions: RequestOptions(path: '/auth/token/refresh'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/auth/token/refresh'),
          ),
        );

        await interceptor.onError(error, mockErrorHandler);

        verify(() => mockStorage.clearTokens()).called(1);
        verify(() => mockErrorHandler.next(error)).called(1);
      });

      test('should attempt token refresh on 401 for protected endpoints', () async {
        when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'valid-refresh-token');
        when(() => mockStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
        when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => 'new-access-token');

        when(() => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          statusCode: 200,
          data: {
            'token': 'new-access-token',
            'refresh_token': 'new-refresh-token',
          },
          requestOptions: RequestOptions(path: '/auth/token/refresh'),
        ));

        when(() => mockDio.request<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          statusCode: 200,
          data: {'success': true},
          requestOptions: RequestOptions(path: '/api/quests'),
        ));

        final error = DioException(
          requestOptions: RequestOptions(path: '/api/quests'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/quests'),
          ),
        );

        await interceptor.onError(error, mockErrorHandler);

        verify(() => mockDio.post<Map<String, dynamic>>(
          '/auth/token/refresh',
          data: {'refresh_token': 'valid-refresh-token'},
          options: any(named: 'options'),
        )).called(1);

        verify(() => mockStorage.saveTokens(
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
        )).called(1);
      });

      test('should pass error when no refresh token available', () async {
        when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => null);

        final error = DioException(
          requestOptions: RequestOptions(path: '/api/quests'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/quests'),
          ),
        );

        await interceptor.onError(error, mockErrorHandler);

        verify(() => mockErrorHandler.next(error)).called(1);
        verifyNever(() => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ));
      });

      test('should clear tokens when refresh fails', () async {
        when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'expired-refresh-token');
        when(() => mockStorage.clearTokens())
          .thenAnswer((_) async {});

        when(() => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/token/refresh'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/auth/token/refresh'),
          ),
        ));

        final error = DioException(
          requestOptions: RequestOptions(path: '/api/quests'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/quests'),
          ),
        );

        await interceptor.onError(error, mockErrorHandler);

        verify(() => mockStorage.clearTokens()).called(1);
        verify(() => mockErrorHandler.next(error)).called(1);
      });
    });
  });
}
