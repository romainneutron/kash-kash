import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Route names
abstract class AppRoutes {
  static const login = '/login';
  static const questList = '/';
  static const questDetail = '/quest/:id';
  static const activeQuest = '/quest/:id/play';
  static const history = '/history';
  static const adminQuestList = '/admin/quests';
  static const adminQuestEdit = '/admin/quests/:id';
  static const adminQuestCreate = '/admin/quests/new';
}

/// Auth state for redirects
@riverpod
class AuthState extends _$AuthState {
  @override
  bool build() => false; // Default: not authenticated
}

/// App router provider
@riverpod
GoRouter appRouter(Ref ref) {
  final isAuthenticated = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.questList,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !isLoginRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isLoginRoute) {
        return AppRoutes.questList;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.questList,
        name: 'questList',
        builder: (context, state) => const _PlaceholderScreen(title: 'Nearby Quests'),
      ),
      GoRoute(
        path: AppRoutes.questDetail,
        name: 'questDetail',
        builder: (context, state) {
          final questId = state.pathParameters['id']!;
          return _PlaceholderScreen(title: 'Quest: $questId');
        },
      ),
      GoRoute(
        path: AppRoutes.activeQuest,
        name: 'activeQuest',
        builder: (context, state) {
          final questId = state.pathParameters['id']!;
          return _PlaceholderScreen(title: 'Playing: $questId');
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        builder: (context, state) => const _PlaceholderScreen(title: 'History'),
      ),
      GoRoute(
        path: AppRoutes.adminQuestList,
        name: 'adminQuestList',
        builder: (context, state) => const _PlaceholderScreen(title: 'Admin: Quests'),
      ),
      GoRoute(
        path: AppRoutes.adminQuestCreate,
        name: 'adminQuestCreate',
        builder: (context, state) => const _PlaceholderScreen(title: 'Create Quest'),
      ),
      GoRoute(
        path: AppRoutes.adminQuestEdit,
        name: 'adminQuestEdit',
        builder: (context, state) {
          final questId = state.pathParameters['id']!;
          return _PlaceholderScreen(title: 'Edit Quest: $questId');
        },
      ),
    ],
    errorBuilder: (context, state) => _PlaceholderScreen(
      title: 'Error: ${state.error}',
    ),
  );
}

/// Temporary placeholder screen for routes
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text('(Placeholder Screen)'),
          ],
        ),
      ),
    );
  }
}
