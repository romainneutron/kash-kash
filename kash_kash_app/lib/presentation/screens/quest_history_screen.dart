import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/distance_calculator.dart';
import '../../core/utils/duration_formatter.dart';
import '../../domain/entities/quest_attempt.dart';
import '../providers/quest_history_provider.dart';
import '../widgets/widgets.dart';

class QuestHistoryScreen extends ConsumerWidget {
  const QuestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(questHistoryProvider);
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest History'),
      ),
      body: Column(
        children: [
          // Filter chips
          _HistoryFilterChips(
            selected: filter,
            onChanged: (f) =>
                ref.read(historyFilterProvider.notifier).setFilter(f),
          ),

          // Main content
          Expanded(
            child: historyAsync.when(
              loading: () => const _HistorySkeleton(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(questHistoryProvider),
              ),
              data: (state) => _buildContent(context, ref, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    QuestHistoryState state,
  ) {
    if (state.hasError) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.invalidate(questHistoryProvider),
      );
    }

    if (state.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        message: _getEmptyMessage(state.filter),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(questHistoryProvider),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.attempts.length,
        itemBuilder: (context, index) {
          final item = state.attempts[index];
          return _HistoryCard(attemptWithQuest: item);
        },
      ),
    );
  }

  String _getEmptyMessage(HistoryFilter filter) {
    return switch (filter) {
      HistoryFilter.all => 'No quest history yet. Start playing to see your attempts here.',
      HistoryFilter.completed => 'No completed quests yet. Keep exploring!',
      HistoryFilter.abandoned => 'No abandoned quests. Great job sticking with it!',
    };
  }
}

class _HistoryFilterChips extends StatelessWidget {
  final HistoryFilter selected;
  final ValueChanged<HistoryFilter> onChanged;

  const _HistoryFilterChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: HistoryFilter.values.map((filter) {
          final isSelected = filter == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_getFilterLabel(filter)),
                selected: isSelected,
                onSelected: (_) => onChanged(filter),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(HistoryFilter filter) {
    return switch (filter) {
      HistoryFilter.all => 'All',
      HistoryFilter.completed => 'Completed',
      HistoryFilter.abandoned => 'Abandoned',
    };
  }
}

class _HistoryCard extends StatelessWidget {
  final QuestAttemptWithQuest attemptWithQuest;

  const _HistoryCard({required this.attemptWithQuest});

  @override
  Widget build(BuildContext context) {
    final attempt = attemptWithQuest.attempt;
    final quest = attemptWithQuest.quest;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with status icon and title
            Row(
              children: [
                _buildStatusIcon(context, attempt.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest?.title ?? 'Unknown Quest',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(attempt.startedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _formatDuration(attempt.durationSeconds),
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  context,
                  icon: Icons.directions_walk,
                  label: 'Distance',
                  value: _formatDistance(attempt.distanceWalked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, AttemptStatus status) {
    final IconData icon;
    final Color color;

    switch (status) {
      case AttemptStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
      case AttemptStatus.abandoned:
        icon = Icons.cancel;
        color = Colors.orange;
      case AttemptStatus.inProgress:
        icon = Icons.play_circle;
        color = Colors.blue;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy · h:mm a').format(date);
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--';
    return DurationFormatter.formatHuman(Duration(seconds: seconds));
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '--';
    return DistanceCalculator.formatDistance(meters);
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
