import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kash_kash_app/data/datasources/remote/api/api_client.dart';
import 'package:kash_kash_app/infrastructure/storage/secure_storage.dart';

part 'api_provider.g.dart';

@Riverpod(keepAlive: true)
SecureStorage secureStorage(Ref ref) {
  return SecureStorage();
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: storage);
}
