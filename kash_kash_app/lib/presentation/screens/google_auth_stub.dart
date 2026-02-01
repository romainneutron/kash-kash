import 'package:flutter/material.dart';

/// Stub for web - WebView is not available
Widget buildGoogleAuthWebView({
  required String authUrl,
  required void Function(
          String accessToken, String refreshToken, Map<String, dynamic> userData)
      onAuthComplete,
  required void Function(String error) onError,
}) {
  // Should never be called on web
  throw UnsupportedError('WebView is not supported on web');
}
