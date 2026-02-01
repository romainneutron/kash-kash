import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kash_kash_app/presentation/providers/auth_provider.dart';

// Conditional import: use stub on web, real implementation on mobile
import 'google_auth_stub.dart'
    if (dart.library.io) 'google_auth_mobile.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo placeholder with icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Kash-Kash',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Find treasures near you',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 48),

                // Error message
                if (authState.status == AuthStatus.error &&
                    authState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: Text(
                      authState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Sign in button
                if (authState.isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Signing in...'),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startGoogleSignIn(context, ref),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google "G" icon
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGoogleSignIn(BuildContext context, WidgetRef ref) async {
    if (kIsWeb) {
      // On web, get current URL (without fragment) as redirect target
      final currentUrl = Uri.base.removeFragment().toString();
      final authUrl = ref.read(authProvider.notifier).getGoogleAuthUrl(
            webRedirectUri: currentUrl,
          );
      await _launchWebAuth(context, authUrl);
    } else {
      // On mobile, use WebView (no redirect needed)
      final authUrl = ref.read(authProvider.notifier).getGoogleAuthUrl();
      _launchMobileAuth(context, ref, authUrl);
    }
  }

  Future<void> _launchWebAuth(BuildContext context, String authUrl) async {
    final uri = Uri.parse(authUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open sign-in page')),
        );
      }
    }
  }

  void _launchMobileAuth(BuildContext context, WidgetRef ref, String authUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => buildGoogleAuthWebView(
          authUrl: authUrl,
          onAuthComplete: (accessToken, refreshToken, userData) {
            Navigator.of(context).pop();
            ref.read(authProvider.notifier).handleAuthCallback(
                  accessToken: accessToken,
                  refreshToken: refreshToken,
                  userData: userData,
                );
          },
          onError: (error) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sign-in failed: $error'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        ),
      ),
    );
  }
}
