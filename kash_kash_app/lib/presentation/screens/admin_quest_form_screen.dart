import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/coordinate_validators.dart';
import '../../domain/entities/quest.dart';
import '../../router/app_router.dart';
import '../providers/admin_quest_form_provider.dart';
import '../providers/admin_quest_list_provider.dart';
import '../widgets/widgets.dart';

class AdminQuestFormScreen extends ConsumerStatefulWidget {
  final String? questId;

  const AdminQuestFormScreen({super.key, this.questId});

  @override
  ConsumerState<AdminQuestFormScreen> createState() =>
      _AdminQuestFormScreenState();
}

class _AdminQuestFormScreenState extends ConsumerState<AdminQuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _controllersInitialized = false;
  late AdminQuestFormNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(adminQuestFormProvider(widget.questId).notifier);
  }

  @override
  void didUpdateWidget(AdminQuestFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questId != widget.questId) {
      _controllersInitialized = false;
      _notifier = ref.read(adminQuestFormProvider(widget.questId).notifier);
    }
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
    } else {
      // Clear location when either field is empty/invalid to prevent
      // stale coordinates from being retained in provider state.
      _notifier.clearLocation();
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
        error: (error, _) => ErrorView(
          message: error is Failure ? error.message : error.toString(),
          onRetry: () => ref.invalidate(adminQuestFormProvider(widget.questId)),
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

            if (state.isSaving) const LinearProgressIndicator(),

            const SizedBox(height: 16),

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
                if (value.trim().length > QuestFormData.maxTitleLength) {
                  return 'Title must be ${QuestFormData.maxTitleLength} characters or less';
                }
                return null;
              },
              onChanged: _notifier.updateTitle,
            ),

            const SizedBox(height: 16),

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

            DropdownButtonFormField<QuestDifficulty>(
              key: ValueKey('difficulty_${state.formData.difficulty}'),
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

            DropdownButtonFormField<LocationType>(
              key: ValueKey('locationType_${state.formData.locationType}'),
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

            Text(
              'Location',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude *',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: CoordinateValidators.validateLatitude,
              onChanged: (_) => _updateCoordinates(),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude *',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: CoordinateValidators.validateLongitude,
              onChanged: (_) => _updateCoordinates(),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: state.isSaving || state.isLocating
                  ? null
                  : _onUseCurrentLocation,
              icon: state.isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                  state.isLocating ? 'Locating...' : 'Use Current Location'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _onUseCurrentLocation() async {
    await _notifier.useCurrentLocation();

    final asyncState = ref.read(adminQuestFormProvider(widget.questId));
    if (asyncState case AsyncData(:final value)
        when value.formData.hasLocation) {
      _latitudeController.text = value.formData.latitude.toString();
      _longitudeController.text = value.formData.longitude.toString();
    }
  }

  Future<void> _onSave() async {
    // UI-level validation (field format). The provider also validates
    // required fields and coordinate ranges as defense-in-depth.
    if (!_formKey.currentState!.validate()) return;

    final result = await _notifier.save();

    if (result.isRight() && mounted) {
      ref.invalidate(adminQuestListProvider);
      context.go(AppRoutes.adminQuestList);
    }
  }
}
