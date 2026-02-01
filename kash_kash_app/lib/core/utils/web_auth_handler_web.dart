import 'package:web/web.dart' as web;

/// Gets auth tokens from URL fragment if present (web OAuth callback)
Map<String, String>? getAuthTokensFromUrl() {
  final fragment = web.window.location.hash;
  if (fragment.isEmpty || !fragment.contains('token=')) {
    return null;
  }

  // Remove leading # and parse as query string
  final params = Uri.splitQueryString(fragment.substring(1));

  if (params.containsKey('token') && params.containsKey('refresh_token')) {
    return params;
  }

  return null;
}

/// Clears the auth fragment from URL to clean up the address bar
void clearAuthFragment() {
  final currentUrl = web.window.location.href;
  final hashIndex = currentUrl.indexOf('#');
  if (hashIndex != -1) {
    final cleanUrl = currentUrl.substring(0, hashIndex);
    web.window.history.replaceState(null, '', cleanUrl);
  }
}
