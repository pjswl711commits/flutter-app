import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/logger.dart';

/// Keychain (iOS/macOS) / EncryptedSharedPreferences-backed (Android) token store.
class TokenStorage {
  static const _key = 'access_token';
  final FlutterSecureStorage _storage;

  const TokenStorage([this._storage = const FlutterSecureStorage()]);

  Future<String?> read() async {
    final token = await _storage.read(key: _key);
    logd('Token', 'Get token -> ${maskToken(token)}');
    return token;
  }

  Future<void> write(String token) async {
    await _storage.write(key: _key, value: token);
    logd('Token', 'store token -> ${maskToken(token)}');
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    logd('Token', 'remove token');
  }
}
