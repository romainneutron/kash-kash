import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/quest.dart';
import '../providers/admin_quest_form_provider.dart';

class AdminQuestFormScreen extends ConsumerStatefulWidget {
  final String? questId;

  const AdminQuestFormScreen({super.key, this.questId});

  @override
  ConsumerState<AdminQuestFormScreen> createState() =>
      _AdminQuestFormScreenState();
}

class _AdminQuestFormScreenState extends ConsumerState<AdminQuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  bool _controllersInitialized = false;

  AdminQuestFormNotifier get _notifier =>
      ref.read(adminQuestFormProvider(widget.questId).notifier);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _initControllers(AdminQuestFormState formState) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;

    _titleController.text = formState.formData.title;
    _descriptionController.text = formState.formData.description;
    if (formState.formData.latitude != null) {
      _latitudeController.text = formState.formData.latitude.toString();
    }
    if (formState.formData.longitude != null) {
      _longitudeController.text = formState.formData.longitude.toString();
    }
  }

  void _updateCoordinates() {
    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());
    if (lat != null && lng != null) {
      _notifier.updateLocation(latitude: lat, longitude: lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState =
        ref.watch(adminQuestFormProvider(widget.questId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.questId == null ? 'Create Quest' : 'Edit Quest'),
        actions: [
          asyncState.whenOrNull(
                data: (state) => TextButton(
                  onPressed: state.isSaving ? null : _onSave,
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (state) {
          _initControllers(state);
          return _buildForm(context, state);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, AdminQuestFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner
            if (state.hasError)
              MaterialBanner(
                content: Text(state.error!),
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer,
                contentTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                actions: [
                  TextButton(
                    onPressed: _notifier.clearError,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),

            // Saving indicator
            if (state.isSaving) const LinearProgressIndicator(),

            const SizedBox(height: 16),

            // Title field
            TextFormField(
              controller: _titleController,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              onChanged: _notifier.updateTitle,
            ),

            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: _notifier.updateDescription,
            ),

            const SizedBox(height: 16),

            // Difficulty dropdown
            DropdownButtonFormField<QuestDifficulty>(
              initialValue: state.formData.difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                ...QuestDifficulty.values.map(
                  (d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.name),
                  ),
                ),
              ],
              onChanged: _notifier.updateDifficulty,
            ),

            const SizedBox(height: 16),

            // Location type dropdown
            DropdownButtonFormField<LocationType>(
              initialValue: state.formData.locationType,
              decoration: const InputDecoration(
                labelText: 'Location Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                ...LocationType.values.map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.name),
                  ),
                ),
              ],
              onChanged: _notifier.updateLocationType,
            ),

            const SizedBox(height: 16),

            // Radius slider
            Text(
              'Radius: ${state.formData.radiusMeters.toStringAsFixed(0)} m',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: state.formData.radiusMeters,
              min: 1,
              max: 20,
              divisions: 19,
              label: '${state.formData.radiusMeters.toStringAsFixed(0)} m',
              onChanged: _notifier.updateRadius,
            ),

            const SizedBox(height: 16),

            // Location section
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // Latitude field
            TextFormField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude *',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Latitude is required';
                }
                final lat = double.tryParse(value.trim());
                if (lat == null || lat < -90 || lat > 90) {
                  return 'Must be between -90 and 90';
                }
                return null;
              },
              onChanged: (_) => _updateCoordinates(),
            ),

            const SizedBox(height: 16),

            // Longitude field
            TextFormField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude *',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Longitude is required';
                }
                final lng = double.tryParse(value.trim());
                if (lng == null || lng < -180 || lng > 180) {
                  return 'Must be between -180 and 180';
                }
                return null;
              },
              onChanged: (_) => _updateCoordinates(),
            ),

            const SizedBox(height: 16),

            // Use Current Location button
            OutlinedButton.icon(
              onPressed: state.isSaving ? null : _onUseCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _onUseCurrentLocation() async {
    await _notifier.useCurrentLocation();

    // Update text controllers with new location
    final asyncFormState =
        ref.read(adminQuestFormProvider(widget.questId));
    final formState = switch (asyncFormState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (formState != null && formState.formData.hasLocation) {
      _latitudeController.text = formState.formData.latitude.toString();
      _longitudeController.text = formState.formData.longitude.toString();
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await _notifier.save();

    if (result.isRight() && mounted) {
      context.go('/admin/quests');
    }
  }
}
