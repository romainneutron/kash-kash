import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/quest.dart';
import '../providers/admin_quest_list_provider.dart';
import '../widgets/widgets.dart';

class AdminQuestListScreen extends ConsumerStatefulWidget {
  const AdminQuestListScreen({super.key});

  @override
  ConsumerState<AdminQuestListScreen> createState() =>
      _AdminQuestListScreenState();
}

class _AdminQuestListScreenState extends ConsumerState<AdminQuestListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminQuestListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quests'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/quests/new'),
        child: const Icon(Icons.add),
      ),
      body: asyncState.when(
        loading: () => const _AdminQuestListSkeleton(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(adminQuestListProvider.notifier).refresh(),
        ),
        data: (state) => _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminQuestListState state) {
    if (state.hasError && state.quests.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(adminQuestListProvider.notifier).refresh(),
      );
    }

    return Column(
      children: [
        // Error banner
        if (state.hasError && state.quests.isNotEmpty)
          MaterialBanner(
            content: Text(state.error!),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(adminQuestListProvider.notifier)
                    .refresh(),
                child: const Text('Dismiss'),
              ),
            ],
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search quests...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(adminQuestListProvider.notifier)
                            .setSearchQuery('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref
                  .read(adminQuestListProvider.notifier)
                  .setSearchQuery(value);
              setState(() {}); // Update clear button visibility
            },
          ),
        ),

        // Saving indicator
        if (state.isSaving) const LinearProgressIndicator(),

        // Quest list
        Expanded(
          child: state.isEmpty
              ? EmptyState(
                  icon: Icons.quiz_outlined,
                  message: state.searchQuery.isNotEmpty
                      ? 'No quests match your search.'
                      : 'No quests yet. Create your first quest!',
                  actionLabel:
                      state.searchQuery.isEmpty ? 'Create Quest' : null,
                  onAction: state.searchQuery.isEmpty
                      ? () => context.push('/admin/quests/new')
                      : null,
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminQuestListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.filteredQuests.length,
                    itemBuilder: (context, index) {
                      final quest = state.filteredQuests[index];
                      return _AdminQuestCard(
                        quest: quest,
                        isSaving: state.isSaving,
                        onTogglePublished: () => ref
                            .read(adminQuestListProvider.notifier)
                            .togglePublished(quest),
                        onEdit: () =>
                            context.push('/admin/quests/${quest.id}'),
                        onDelete: () =>
                            _showDeleteConfirmation(context, quest),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, Quest quest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text('Are you sure you want to delete "${quest.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(adminQuestListProvider.notifier).deleteQuest(quest.id);
    }
  }
}

class _AdminQuestCard extends StatelessWidget {
  final Quest quest;
  final bool isSaving;
  final VoidCallback onTogglePublished;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminQuestCard({
    required this.quest,
    required this.isSaving,
    required this.onTogglePublished,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with status and title
            Row(
              children: [
                // Published status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: quest.published ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quest.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Subtitle with coordinates and metadata
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quest.latitude.toStringAsFixed(4)}, ${quest.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (quest.difficulty != null || quest.locationType != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (quest.difficulty != null)
                            _buildChip(context, quest.difficulty!.name),
                          if (quest.difficulty != null &&
                              quest.locationType != null)
                            const SizedBox(width: 8),
                          if (quest.locationType != null)
                            _buildChip(context, quest.locationType!.name),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Publish toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Published',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Switch(
                      value: quest.published,
                      onChanged: isSaving ? null : (_) => onTogglePublished(),
                    ),
                  ],
                ),
                const Spacer(),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: isSaving ? null : onEdit,
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: isSaving ? null : onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _AdminQuestListSkeleton extends StatelessWidget {
  const _AdminQuestListSkeleton();

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
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
          ),
        );
      },
    );
  }
}
