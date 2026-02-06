import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/coordinate_validators.dart';
import '../../domain/entities/quest.dart';
import '../../router/app_router.dart';
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
  Timer? _debounceTimer;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
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
        onPressed: () => context.push(AppRoutes.adminQuestCreate),
        child: const Icon(Icons.add),
      ),
      body: asyncState.when(
        loading: () => const _AdminQuestListSkeleton(),
        error: (error, _) => ErrorView(
          message: error is Failure ? error.message : error.toString(),
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
        if (state.hasError && state.quests.isNotEmpty)
          MaterialBanner(
            content: Text(state.error!),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(adminQuestListProvider.notifier)
                    .clearError(),
                child: const Text('Dismiss'),
              ),
            ],
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search quests...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.searchQuery.isNotEmpty
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
              _debounceTimer?.cancel();
              final notifier = ref.read(adminQuestListProvider.notifier);
              _debounceTimer = Timer(
                const Duration(milliseconds: 300),
                () {
                  if (_disposed) return;
                  notifier.setSearchQuery(value);
                },
              );
            },
          ),
        ),

        if (state.isSaving) const LinearProgressIndicator(),

        Expanded(
          child: state.isFilteredEmpty
              ? EmptyState(
                  icon: Icons.quiz_outlined,
                  message: state.searchQuery.isNotEmpty
                      ? 'No quests match your search.'
                      : 'No quests yet. Create your first quest!',
                  actionLabel:
                      state.searchQuery.isEmpty ? 'Create Quest' : null,
                  onAction: state.searchQuery.isEmpty
                      ? () => context.push(AppRoutes.adminQuestCreate)
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
                        onEdit: () => context.push(
                            AppRoutes.adminQuestEdit
                                .replaceFirst(':id', quest.id)),
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
        content: Text(
          'Are you sure you want to delete "${quest.title}"?',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
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
      await ref.read(adminQuestListProvider.notifier).deleteQuest(quest.id);
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
            Row(
              children: [
                Semantics(
                  label: quest.published ? 'Published' : 'Unpublished',
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: quest.published ? Colors.green : Colors.grey,
                    ),
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

            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CoordinateValidators.formatLatLng(quest.latitude, quest.longitude),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (quest.difficulty != null || quest.locationType != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (quest.difficulty != null)
                            _buildChip(context, quest.difficulty!.name),
                          if (quest.locationType != null)
                            _buildChip(context, quest.locationType!.name),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: isSaving ? null : onEdit,
                ),
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
