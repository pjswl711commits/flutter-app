import 'dart:developer';

import 'package:flutter/foundation.dart';

/// Debug-only console logging. Silent in release builds.
void logd(String tag, String message) {
  if (kDebugMode) log('[$tag] $message');
}

/// Shows just enough of a secret to tell tokens apart without leaking them.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return 'null';
  if (token.length <= 12) return '***';
  return '$token (len ${token.length})';
}
