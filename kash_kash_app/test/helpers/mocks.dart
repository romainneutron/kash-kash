import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kash_kash_app/infrastructure/storage/secure_storage.dart';
import 'package:kash_kash_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:dio/dio.dart';

// Mock classes for testing

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSecureStorage extends Mock implements SecureStorage {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockDio extends Mock implements Dio {}

class MockRequestOptions extends Mock implements RequestOptions {}

class MockResponse<T> extends Mock implements Response<T> {}

class MockDioException extends Mock implements DioException {}
