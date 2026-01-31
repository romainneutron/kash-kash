import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils/duration_formatter.dart';
import '../providers/active_quest_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/win_overlay.dart';

/// Active quest gameplay screen.
///
/// Displays full-screen color feedback based on gameplay state:
/// - BLACK: stationary (not moving)
/// - RED: getting closer to target
/// - BLUE: getting farther from target
/// - GREEN: won (reached target)
class ActiveQuestScreen extends ConsumerStatefulWidget {
  /// The quest ID to play.
  final String questId;

  const ActiveQuestScreen({
    super.key,
    required this.questId,
  });

  @override
  ConsumerState<ActiveQuestScreen> createState() => _ActiveQuestScreenState();
}

class _ActiveQuestScreenState extends ConsumerState<ActiveQuestScreen> {
  @override
  void initState() {
    super.initState();
    // Prevent screen sleep during gameplay
    WakelockPlus.enable();
    // Hide status bar for immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Re-enable screen sleep
    WakelockPlus.disable();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(activeQuestProvider(widget.questId));

    return Scaffold(
      body: asyncState.when(
        loading: () => const _LoadingView(),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onBack: () => context.go('/quests'),
        ),
        data: (state) => _GameplayView(
          state: state,
          onAbandon: () => _confirmAbandon(context),
        ),
      ),
    );
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    // Capture router before async gap
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Quest?'),
        content: const Text(
          'Your progress will be saved but marked as abandoned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(activeQuestProvider(widget.questId).notifier)
          .abandon();
      if (mounted) {
        router.go('/quests');
      }
    }
  }
}

/// Loading view while initializing gameplay.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Starting quest...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error view when gameplay fails to start.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorView({
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to start quest',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBack,
              child: const Text('Back to Quests'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main gameplay view with color feedback.
class _GameplayView extends StatelessWidget {
  final ActiveQuestState state;
  final VoidCallback onAbandon;

  const _GameplayView({
    required this.state,
    required this.onAbandon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen colored background
        GameBackground(
          state: state.gameplayState,
        ),

        // Subtle controls at top
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Abandon button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  tooltip: 'Abandon Quest',
                  onPressed: onAbandon,
                ),

                // Elapsed time
                Text(
                  DurationFormatter.formatTimer(state.elapsed),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Win overlay when completed
        if (state.hasWon)
          WinOverlay(
            elapsed: state.elapsed,
            distanceWalked: state.attempt.distanceWalked ?? 0,
            questTitle: state.quest.title,
            onDone: () => GoRouter.of(context).go('/quests'),
          ),
      ],
    );
  }
}
