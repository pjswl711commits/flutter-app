import 'package:flutter/material.dart';

import 'app.dart';
import 'data/services/api_client.dart';
import 'data/services/token_storage.dart';
import 'features/auth/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final auth = AuthController(api, const TokenStorage())..restore();
  runApp(App(api: api, auth: auth));
}
