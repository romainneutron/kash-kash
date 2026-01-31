import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/screens/login_screen.dart';
import 'package:kash_kash_app/presentation/screens/quest_list_screen.dart';
import 'package:kash_kash_app/presentation/widgets/error_boundary.dart';

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

/// App router provider
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = authState.isAuthenticated;
  final isAdmin = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: AppRoutes.questList,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on login page, redirect to quest list
      if (isAuthenticated && isLoginRoute) {
        return AppRoutes.questList;
      }

      // If trying to access admin routes without admin role, redirect to quest list
      if (isAdminRoute && !isAdmin) {
        return AppRoutes.questList;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.questList,
        name: 'questList',
        builder: (context, state) => const ErrorBoundary(
          child: QuestListScreen(),
        ),
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
