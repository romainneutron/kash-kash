import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Builds the Google Auth WebView for mobile platforms
Widget buildGoogleAuthWebView({
  required String authUrl,
  required void Function(
          String accessToken, String refreshToken, Map<String, dynamic> userData)
      onAuthComplete,
  required void Function(String error) onError,
}) {
  return _GoogleAuthWebView(
    authUrl: authUrl,
    onAuthComplete: onAuthComplete,
    onError: onError,
  );
}

class _GoogleAuthWebView extends StatefulWidget {
  final String authUrl;
  final void Function(
      String accessToken, String refreshToken, Map<String, dynamic> userData)
      onAuthComplete;
  final void Function(String error) onError;

  const _GoogleAuthWebView({
    required this.authUrl,
    required this.onAuthComplete,
    required this.onError,
  });

  @override
  State<_GoogleAuthWebView> createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<_GoogleAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkForAuthCallback(url);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            widget.onError(error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  void _checkForAuthCallback(String url) async {
    if (url.contains('/auth/google/callback')) {
      try {
        final content = await _controller.runJavaScriptReturningResult(
          'document.body.innerText',
        );

        if (content is String) {
          var jsonStr = content;
          if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
            jsonStr = jsonStr.substring(1, jsonStr.length - 1);
            jsonStr = jsonStr.replaceAll(r'\n', '\n').replaceAll(r'\"', '"');
          }

          final data = jsonDecode(jsonStr) as Map<String, dynamic>;

          if (data.containsKey('token') && data.containsKey('refresh_token')) {
            widget.onAuthComplete(
              data['token'] as String,
              data['refresh_token'] as String,
              data['user'] as Map<String, dynamic>,
            );
            return;
          }
        }
      } catch (e) {
        // Not the expected callback page, continue
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
