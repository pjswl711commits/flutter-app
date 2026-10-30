import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../data/services/api_client.dart';
import '../../data/services/token_storage.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthController(this._api, this._storage);

  AuthStatus status = AuthStatus.unknown;
  String? token;
  bool loading = false;
  String? error;

  /// Restores a previously stored session on app start.
  Future<void> restore() async {
    token = await _storage.read();
    status = token == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      token = await _api.login(username, password);
      await _storage.write(token!);
      status = AuthStatus.signedIn;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    token = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
