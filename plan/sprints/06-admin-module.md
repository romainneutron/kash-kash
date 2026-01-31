# Sprint 6: Admin Module

**Goal**: Implement admin functionality for quest creation and management with map-based location picking.

**Deliverable**: Admin users can create, edit, and manage quests using an OpenStreetMap interface.

**Prerequisites**: Sprint 5 completed (history and analytics working)

---

## Tasks

### S6-T1: Admin Quest List Provider
**Type**: feature
**Dependencies**: S3-T5

**Description**:
Create provider for admin quest management.

**Acceptance Criteria**:
- [ ] List all quests (not just published)
- [ ] Include analytics summary
- [ ] Support search/filter
- [ ] Toggle publish status

**Implementation**:
```dart
@riverpod
class AdminQuestListNotifier extends _$AdminQuestListNotifier {
  @override
  FutureOr<AdminQuestListState> build() async {
    SentryService.addBreadcrumb('Admin: Loading quest list', category: 'admin');
    final quests = await ref.read(questRepositoryProvider).getAllQuests();
    final analytics = await ref.read(analyticsRepositoryProvider)
      .getQuestsSummary();

    return AdminQuestListState(
      quests: quests,
      analytics: analytics,
    );
  }

  Future<void> togglePublished(String questId, bool published) async {
    await ref.read(questRepositoryProvider).updateQuest(
      questId,
      published: published,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteQuest(String questId) async {
    SentryService.addBreadcrumb('Admin: Quest deleted', category: 'admin', data: {
      'quest_id': questId,
    });
    await ref.read(questRepositoryProvider).deleteQuest(questId);
    ref.invalidateSelf();
  }
}

class AdminQuestListState {
  final List<Quest> quests;
  final AnalyticsSummary analytics;
  final String? searchQuery;

  List<Quest> get filteredQuests {
    if (searchQuery == null || searchQuery!.isEmpty) return quests;
    return quests.where((q) =>
      q.title.toLowerCase().contains(searchQuery!.toLowerCase())
    ).toList();
  }
}

class AnalyticsSummary {
  final int totalPlays;
  final int currentlyPlaying;
  final int completedToday;
  final double abandonmentRate;
}
```

---

### S6-T2: Admin Quest List Screen
**Type**: feature
**Dependencies**: S6-T1

**Description**:
Build admin quest management screen.

**Acceptance Criteria**:
- [ ] List all quests with status
- [ ] Analytics summary cards at top
- [ ] Search/filter functionality
- [ ] Publish/unpublish toggle
- [ ] Edit and delete buttons
- [ ] Create quest FAB

**Implementation**:
```dart
class AdminQuestListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminQuestListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/admin/analytics'),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (data) => Column(
          children: [
            // Analytics summary
            AnalyticsSummaryCards(analytics: data.analytics),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search quests...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (q) => ref.read(adminQuestListNotifierProvider.notifier)
                  .setSearchQuery(q),
              ),
            ),

            // Quest list
            Expanded(
              child: ListView.builder(
                itemCount: data.filteredQuests.length,
                itemBuilder: (_, i) => AdminQuestCard(
                  quest: data.filteredQuests[i],
                  onTogglePublish: (published) => ref
                    .read(adminQuestListNotifierProvider.notifier)
                    .togglePublished(data.filteredQuests[i].id, published),
                  onEdit: () => context.push(
                    '/admin/quests/${data.filteredQuests[i].id}/edit'),
                  onDelete: () => _confirmDelete(
                    context, ref, data.filteredQuests[i]),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/quests/new'),
        icon: const Icon(Icons.add),
        label: const Text('Create Quest'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Quest quest
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quest?'),
        content: Text('Delete "${quest.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminQuestListNotifierProvider.notifier)
        .deleteQuest(quest.id);
    }
  }
}

class AdminQuestCard extends StatelessWidget {
  final Quest quest;
  final ValueChanged<bool> onTogglePublish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(quest.title),
        subtitle: Text(
          '${quest.latitude.toStringAsFixed(4)}, ${quest.longitude.toStringAsFixed(4)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: quest.published,
              onChanged: onTogglePublish,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### S6-T3: Map Picker Widget
**Type**: feature
**Dependencies**: S1-T2

**Description**:
Create interactive OpenStreetMap component for location selection.

**Acceptance Criteria**:
- [ ] Display OSM tiles
- [ ] Tap to place/move marker
- [ ] Show current coordinates
- [ ] Center on user location option
- [ ] Zoom controls

**Implementation**:
```dart
class MapPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final ValueChanged<LatLng> onLocationChanged;

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedLocation ?? const LatLng(48.8566, 2.3522),
            initialZoom: 15.0,
            onTap: (tapPosition, latLng) {
              setState(() => _selectedLocation = latLng);
              widget.onLocationChanged(latLng);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.kashkash.app',
            ),
            if (_selectedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Coordinates display
        if (_selectedLocation != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
              child: Text(
                '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),

        // Center on user location
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _centerOnUserLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Future<void> _centerOnUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 17);
      setState(() => _selectedLocation = latLng);
      widget.onLocationChanged(latLng);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
  }
}
```

---

### S6-T4: Quest Form Widget
**Type**: feature
**Dependencies**: S1-T8

**Description**:
Create form for quest metadata entry.

**Acceptance Criteria**:
- [ ] Title input (required)
- [ ] Description input (optional)
- [ ] Difficulty selector
- [ ] Location type selector
- [ ] Radius slider (default 3m)
- [ ] Form validation

**Implementation**:
```dart
class QuestForm extends StatefulWidget {
  final Quest? initialQuest;
  final LatLng? selectedLocation;
  final ValueChanged<QuestFormData> onChanged;

  @override
  State<QuestForm> createState() => _QuestFormState();
}

class _QuestFormState extends State<QuestForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  QuestDifficulty? _difficulty;
  LocationType? _locationType;
  double _radius = 3.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialQuest?.title);
    _descriptionController = TextEditingController(
      text: widget.initialQuest?.description);
    _difficulty = widget.initialQuest?.difficulty;
    _locationType = widget.initialQuest?.locationType;
    _radius = widget.initialQuest?.radiusMeters ?? 3.0;
  }

  void _notifyChange() {
    widget.onChanged(QuestFormData(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
        ? null : _descriptionController.text,
      difficulty: _difficulty,
      locationType: _locationType,
      radiusMeters: _radius,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<QuestDifficulty>(
            value: _difficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(),
            ),
            items: QuestDifficulty.values.map((d) => DropdownMenuItem(
              value: d,
              child: Text(d.name.capitalize()),
            )).toList(),
            onChanged: (v) {
              setState(() => _difficulty = v);
              _notifyChange();
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<LocationType>(
            value: _locationType,
            decoration: const InputDecoration(
              labelText: 'Location Type',
              border: OutlineInputBorder(),
            ),
            items: LocationType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.name.capitalize()),
            )).toList(),
            onChanged: (v) {
              setState(() => _locationType = v);
              _notifyChange();
            },
          ),
          const SizedBox(height: 16),

          Text('Win Radius: ${_radius.toStringAsFixed(1)}m'),
          Slider(
            value: _radius,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            label: '${_radius.toStringAsFixed(1)}m',
            onChanged: (v) {
              setState(() => _radius = v);
              _notifyChange();
            },
          ),

          if (widget.selectedLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Location: ${widget.selectedLocation!.latitude.toStringAsFixed(6)}, '
                '${widget.selectedLocation!.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  bool validate() => _formKey.currentState?.validate() ?? false;
}

class QuestFormData {
  final String title;
  final String? description;
  final QuestDifficulty? difficulty;
  final LocationType? locationType;
  final double radiusMeters;
}
```

---

### S6-T5: Quest Edit Provider
**Type**: feature
**Dependencies**: S3-T5

**Description**:
Provider for quest creation and editing.

**Acceptance Criteria**:
- [ ] Load existing quest for edit
- [ ] Create new quest
- [ ] Update existing quest
- [ ] Validate before save
- [ ] Handle errors

**Implementation**:
```dart
@riverpod
class QuestEditNotifier extends _$QuestEditNotifier {
  @override
  FutureOr<QuestEditState> build(String? questId) async {
    if (questId != null) {
      final quest = await ref.read(questRepositoryProvider)
        .getQuestById(questId);
      return quest.fold(
        (_) => QuestEditState.create(),
        (q) => QuestEditState.edit(q),
      );
    }
    return QuestEditState.create();
  }

  void updateForm(QuestFormData data) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(formData: data));
  }

  void updateLocation(LatLng location) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(location: location));
  }

  Future<Either<Failure, Quest>> save() async {
    final current = state.valueOrNull;
    if (current == null) {
      return Left(ValidationFailure('Invalid state'));
    }

    if (current.formData == null || current.location == null) {
      return Left(ValidationFailure('Please fill all required fields'));
    }

    final user = ref.read(currentUserProvider)!;
    final repo = ref.read(questRepositoryProvider);

    SentryService.addBreadcrumb(
      current.isEditing ? 'Admin: Quest updated' : 'Admin: Quest created',
      category: 'admin',
      data: {
        'quest_title': current.formData!.title,
        'is_editing': current.isEditing,
      },
    );

    if (current.isEditing) {
      return repo.updateQuest(current.quest!.id,
        title: current.formData!.title,
        description: current.formData!.description,
        latitude: current.location!.latitude,
        longitude: current.location!.longitude,
        radiusMeters: current.formData!.radiusMeters,
        difficulty: current.formData!.difficulty,
        locationType: current.formData!.locationType,
      );
    } else {
      return repo.createQuest(Quest(
        id: const Uuid().v4(),
        title: current.formData!.title,
        description: current.formData!.description,
        latitude: current.location!.latitude,
        longitude: current.location!.longitude,
        radiusMeters: current.formData!.radiusMeters,
        createdBy: user.id,
        published: false,
        difficulty: current.formData!.difficulty,
        locationType: current.formData!.locationType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }
}

class QuestEditState {
  final Quest? quest;
  final QuestFormData? formData;
  final LatLng? location;
  final bool isEditing;

  QuestEditState._({
    this.quest,
    this.formData,
    this.location,
    required this.isEditing,
  });

  factory QuestEditState.create() => QuestEditState._(isEditing: false);

  factory QuestEditState.edit(Quest quest) => QuestEditState._(
    quest: quest,
    formData: QuestFormData(
      title: quest.title,
      description: quest.description,
      difficulty: quest.difficulty,
      locationType: quest.locationType,
      radiusMeters: quest.radiusMeters,
    ),
    location: LatLng(quest.latitude, quest.longitude),
    isEditing: true,
  );

  QuestEditState copyWith({
    QuestFormData? formData,
    LatLng? location,
  }) => QuestEditState._(
    quest: quest,
    formData: formData ?? this.formData,
    location: location ?? this.location,
    isEditing: isEditing,
  );
}
```

---

### S6-T6: Quest Edit Screen
**Type**: feature
**Dependencies**: S6-T3, S6-T4, S6-T5

**Description**:
Complete quest creation/edit screen.

**Acceptance Criteria**:
- [ ] Map picker (top half)
- [ ] Form (bottom sheet or panel)
- [ ] Save button
- [ ] Validation feedback
- [ ] Loading state during save

**Implementation**:
```dart
class QuestEditScreen extends ConsumerStatefulWidget {
  final String? questId;

  @override
  ConsumerState<QuestEditScreen> createState() => _QuestEditScreenState();
}

class _QuestEditScreenState extends ConsumerState<QuestEditScreen> {
  final _formKey = GlobalKey<_QuestFormState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questEditNotifierProvider(widget.questId));
    final isNew = widget.questId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Create Quest' : 'Edit Quest'),
        actions: [
          state.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (data) => TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (data) => Column(
          children: [
            // Map picker (top half)
            Expanded(
              flex: 1,
              child: MapPicker(
                initialLocation: data.location,
                onLocationChanged: (loc) => ref
                  .read(questEditNotifierProvider(widget.questId).notifier)
                  .updateLocation(loc),
              ),
            ),

            // Form (bottom half)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: QuestForm(
                  key: _formKey,
                  initialQuest: data.quest,
                  selectedLocation: data.location,
                  onChanged: (formData) => ref
                    .read(questEditNotifierProvider(widget.questId).notifier)
                    .updateForm(formData),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final notifier = ref.read(
      questEditNotifierProvider(widget.questId).notifier);
    final result = await notifier.save();

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (quest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quest saved!')),
        );
        context.go('/admin/quests');
      },
    );
  }
}
```

---

### S6-T7: Symfony Admin Quest Endpoints
**Type**: feature
**Dependencies**: S1-T10

**Description**:
Ensure admin-only quest management endpoints work.

**Acceptance Criteria**:
- [ ] POST `/api/quests` requires admin role
- [ ] PUT `/api/quests/{id}` requires admin role
- [ ] DELETE `/api/quests/{id}` requires admin role
- [ ] GET `/api/admin/quests` lists all quests (not just published)

**Implementation**:
```php
// Quest entity already has security annotations
// Add admin-specific endpoint for all quests

#[Route('/api/admin/quests', name: 'admin_quests', methods: ['GET'])]
#[IsGranted('ROLE_ADMIN')]
public function adminList(QuestRepository $repository): JsonResponse
{
    $quests = $repository->findAll();
    return $this->json($quests, context: ['groups' => 'quest:read']);
}
```

---

### S6-T8: Flutter Admin Quest Remote Data Source
**Type**: feature
**Dependencies**: S2-T4

**Description**:
Add admin-specific API calls.

**Acceptance Criteria**:
- [ ] Get all quests (admin)
- [ ] Create quest
- [ ] Update quest
- [ ] Delete quest
- [ ] Toggle publish

**Implementation**:
```dart
class AdminQuestRemoteDataSource {
  final ApiClient _apiClient;

  Future<List<QuestModel>> getAllQuests() async {
    final response = await _apiClient.get('/api/admin/quests');
    final List data = response.data;
    return data.map((json) => QuestModel.fromJson(json)).toList();
  }

  Future<QuestModel> createQuest(QuestModel quest) async {
    final response = await _apiClient.post('/api/quests',
      data: quest.toJson());
    return QuestModel.fromJson(response.data);
  }

  Future<QuestModel> updateQuest(String id, Map<String, dynamic> updates) async {
    final response = await _apiClient.put('/api/quests/$id',
      data: updates);
    return QuestModel.fromJson(response.data);
  }

  Future<void> deleteQuest(String id) async {
    await _apiClient.delete('/api/quests/$id');
  }
}
```

---

## Testing & QA Tasks

### S6-T9: QuestForm Validation Tests
**Type**: test
**Dependencies**: S6-T4

**Description**:
Test quest form validation logic.

**Acceptance Criteria**:
- [ ] Title is required (empty shows error)
- [ ] Description is optional
- [ ] Radius has valid bounds (1-20m)
- [ ] Difficulty selection works
- [ ] Location type selection works
- [ ] Form validation returns correct status

**Test file**: `test/unit/presentation/widgets/quest_form_test.dart`

---

### S6-T10: QuestEditProvider Tests
**Type**: test
**Dependencies**: S6-T5

**Description**:
Test quest edit provider state management.

**Acceptance Criteria**:
- [ ] Create mode initializes with empty state
- [ ] Edit mode loads existing quest data
- [ ] updateForm updates provider state
- [ ] updateLocation updates provider state
- [ ] save creates quest in create mode
- [ ] save updates quest in edit mode
- [ ] Validation errors returned correctly

**Test file**: `test/unit/presentation/providers/quest_edit_provider_test.dart`

---

### S6-T11: Symfony Admin Endpoints Tests
**Type**: test
**Dependencies**: S6-T7

**Description**:
Functional tests for admin quest management endpoints.

**Acceptance Criteria**:
- [ ] POST /api/quests requires ROLE_ADMIN
- [ ] PUT /api/quests/{id} requires ROLE_ADMIN
- [ ] DELETE /api/quests/{id} requires ROLE_ADMIN
- [ ] GET /api/admin/quests returns all quests (including unpublished)
- [ ] Non-admin gets 403 Forbidden on admin endpoints
- [ ] Regular GET /api/quests only returns published

**Test file**: `backend/tests/Functional/Controller/AdminQuestControllerTest.php`

---

### S6-T12: Admin Role Test
**Type**: qa
**Dependencies**: S6-T2, S2-T10

**Description**:
Verify admin role protection works correctly.

**Acceptance Criteria**:
- [ ] Regular user cannot see admin icon in app bar
- [ ] Regular user navigating to /admin/quests is redirected
- [ ] Admin user sees admin icon in app bar
- [ ] Admin user can access /admin/quests
- [ ] Backend returns 403 for non-admin on admin endpoints

**Test accounts needed**: One regular user, one admin user.

---

### S6-T13: Quest Creation Test
**Type**: qa
**Dependencies**: S6-T6

**Description**:
Manually test complete quest creation flow.

**Acceptance Criteria**:
- [ ] Navigate to Create Quest screen
- [ ] Tap on map to place marker
- [ ] Coordinates display updates
- [ ] Fill in title (required)
- [ ] Select difficulty and location type
- [ ] Adjust radius slider (1-20m)
- [ ] Save creates quest
- [ ] New quest appears in admin list (unpublished)
- [ ] Publish quest, verify it appears in user quest list

---

### S6-T14: Quest Edit Test
**Type**: qa
**Dependencies**: S6-T6

**Description**:
Test quest editing functionality.

**Acceptance Criteria**:
- [ ] Open existing quest for editing
- [ ] All fields pre-populated correctly
- [ ] Map shows existing location
- [ ] Change title and save
- [ ] Move marker and save
- [ ] Changes persist after refresh
- [ ] Changes visible in user quest list

---

### S6-T15: Map Picker Usability Test
**Type**: qa
**Dependencies**: S6-T3

**Description**:
Test map picker user experience.

**Acceptance Criteria**:
- [ ] Map loads with OSM tiles
- [ ] Tap to place marker works
- [ ] Marker is clearly visible
- [ ] Zoom in/out works
- [ ] "Center on me" button works
- [ ] Coordinates display accurate
- [ ] Map responsive on both iOS and Android

---

### S6-T16: Publish Toggle Test
**Type**: qa
**Dependencies**: S6-T2

**Description**:
Test quest publish/unpublish functionality.

**Acceptance Criteria**:
- [ ] New quest created as unpublished
- [ ] Unpublished quest NOT visible in user quest list
- [ ] Toggle publish switch in admin list
- [ ] Published quest appears in user quest list
- [ ] Unpublish quest removes from user quest list
- [ ] Toggle state persists across app restart

---

## Sprint 6 Validation

```bash
# Flutter (as admin user)
flutter run --debug
# Go to admin section
# Verify quest list with all quests
# Create new quest with map
# Edit existing quest
# Toggle publish status
# Delete quest with confirmation

# Backend
curl -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "latitude": 48.8566, "longitude": 2.3522}' \
  http://localhost:8080/api/quests
```

**Checklist**:
- [ ] Admin can access admin section
- [ ] Map picker works with tap-to-place
- [ ] Quest form validates
- [ ] Create quest saves to database
- [ ] Edit quest updates database
- [ ] Publish toggle works
- [ ] Delete with confirmation works
- [ ] Non-admin cannot access admin routes

---

## Risk Notes

- OSM tile usage should respect usage policy
- Map performance may vary on older devices
- Large quests lists may need pagination
- Location accuracy depends on device GPS
