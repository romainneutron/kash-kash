import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kash_kash_app/core/utils/distance_calculator.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';
import 'package:kash_kash_app/presentation/theme/app_colors.dart';
import 'package:kash_kash_app/presentation/widgets/widgets.dart';

class QuestListScreen extends ConsumerWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questListState = ref.watch(questListProvider);
    final filter = ref.watch(distanceFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Quests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Quest History',
            onPressed: () => context.push('/history'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'admin':
                  context.push('/admin/quests');
                case 'logout':
                  ref.read(authProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) {
              final isAdmin = ref.read(isAdminProvider);
              return [
                if (isAdmin)
                  const PopupMenuItem(
                    value: 'admin',
                    child: Text('Admin Panel'),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Sign Out'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (questListState.isOffline) const OfflineBanner(),

          // Distance filter tabs
          _DistanceFilterTabs(
            selected: filter,
            onChanged: (f) =>
                ref.read(questListProvider.notifier).setFilter(f),
          ),

          // Main content
          Expanded(
            child: _buildContent(context, ref, questListState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    QuestListState state,
  ) {
    if (state.isLoading) {
      return const _QuestListSkeleton();
    }

    if (state.hasError) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(questListProvider.notifier).refresh(),
      );
    }

    if (state.isEmpty) {
      return EmptyState(
        icon: Icons.explore_off,
        message:
            'No quests nearby. Try increasing the search radius or check back later for new quests.',
        actionLabel: 'Refresh',
        onAction: () => ref.read(questListProvider.notifier).refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(questListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.quests.length,
        itemBuilder: (context, index) {
          final questWithDistance = state.quests[index];
          return _QuestCard(
            quest: questWithDistance.quest,
            distanceMeters: questWithDistance.distanceMeters,
            onTap: () => context.push('/quest/${questWithDistance.quest.id}/play'),
          );
        },
      ),
    );
  }
}

/// Distance filter tab bar.
class _DistanceFilterTabs extends StatelessWidget {
  final DistanceFilter selected;
  final ValueChanged<DistanceFilter> onChanged;

  const _DistanceFilterTabs({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: DistanceFilter.values.map((filter) {
          final isSelected = filter == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(filter.label),
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
}

/// Quest card widget.
class _QuestCard extends StatelessWidget {
  final Quest quest;
  final double distanceMeters;
  final VoidCallback onTap;

  const _QuestCard({
    required this.quest,
    required this.distanceMeters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildDifficultyIcon(context),
        title: Text(
          quest.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.near_me,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  DistanceCalculator.formatDistance(distanceMeters),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (quest.locationType != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    _getLocationTypeIcon(quest.locationType!),
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getLocationTypeLabel(quest.locationType!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (quest.description != null && quest.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  quest.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDifficultyIcon(BuildContext context) {
    final Color color;
    final IconData icon;

    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        color = AppColors.success;
        icon = Icons.sentiment_satisfied;
      case QuestDifficulty.medium:
        color = Colors.orange;
        icon = Icons.sentiment_neutral;
      case QuestDifficulty.hard:
        color = Colors.red;
        icon = Icons.sentiment_dissatisfied;
      case QuestDifficulty.expert:
        color = Colors.purple;
        icon = Icons.whatshot;
      case null:
        color = Theme.of(context).colorScheme.outline;
        icon = Icons.help_outline;
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

  IconData _getLocationTypeIcon(LocationType type) {
    return switch (type) {
      LocationType.city => Icons.location_city,
      LocationType.forest => Icons.forest,
      LocationType.park => Icons.park,
      LocationType.water => Icons.water,
      LocationType.mountain => Icons.terrain,
      LocationType.indoor => Icons.home,
    };
  }

  String _getLocationTypeLabel(LocationType type) {
    return switch (type) {
      LocationType.city => 'City',
      LocationType.forest => 'Forest',
      LocationType.park => 'Park',
      LocationType.water => 'Water',
      LocationType.mountain => 'Mountain',
      LocationType.indoor => 'Indoor',
    };
  }
}

/// Loading skeleton for quest list.
class _QuestListSkeleton extends StatelessWidget {
  const _QuestListSkeleton();

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
            child: Row(
              children: [
                // Icon placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                // Text placeholders
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
                        width: 100,
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
          ),
        );
      },
    );
  }
}
