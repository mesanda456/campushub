import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/subject_controller.dart';
import '../models/subject.dart';

const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Text('No subjects yet. Tap + to add one.'),
            );
          }

          // Group subjects by day, then sort each day's list by start time.
          final byDay = <int, List<Subject>>{};
          for (final subject in subjects) {
            byDay.putIfAbsent(subject.dayOfWeek, () => []).add(subject);
          }
          for (final list in byDay.values) {
            list.sort((a, b) => a.startTime.compareTo(b.startTime));
          }

          final sortedDays = byDay.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
              final day = sortedDays[index];
              final daySubjects = byDay[day]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _dayNames[day],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...daySubjects.map((subject) => _SubjectTile(subject: subject)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSubjectForm(BuildContext context, WidgetRef ref, {Subject? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SubjectFormSheet(existing: existing),
    );
  }
}

class _SubjectTile extends ConsumerWidget {
  final Subject subject;

  const _SubjectTile({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(subject.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(subjectControllerProvider).deleteSubject(subject.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(subject.colorValue),
          ),
          title: Text(subject.name),
          subtitle: Text(
            '${subject.startTime} - ${subject.endTime}'
            '${subject.location != null ? ' • ${subject.location}' : ''}',
          ),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => _SubjectFormSheet(existing: subject),
          ),
        ),
      ),
    );
  }
}

class _SubjectFormSheet extends ConsumerStatefulWidget {
  final Subject? existing;

  const _SubjectFormSheet({this.existing});

  @override
  ConsumerState<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends ConsumerState<_SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  int _dayOfWeek = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Color _selectedColor = Colors.blue;

  static const _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    if (existing != null) {
      _dayOfWeek = existing.dayOfWeek;
      _startTime = _parseTime(existing.startTime);
      _endTime = _parseTime(existing.endTime);
      _selectedColor = Color(existing.colorValue);
    }
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final subject = Subject(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      colorValue: _selectedColor.toARGB32(),
    );

    if (widget.existing != null) {
      ref.read(subjectControllerProvider).updateSubject(subject);
    } else {
      ref.read(subjectControllerProvider).addSubject(subject);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing != null ? 'Edit Subject' : 'Add Subject',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Subject Name'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _dayOfWeek,
              decoration: const InputDecoration(labelText: 'Day'),
              items: List.generate(
                7,
                (i) => DropdownMenuItem(value: i, child: Text(_dayNames[i])),
              ),
              onChanged: (value) => setState(() => _dayOfWeek = value ?? 0),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: true),
                    child: Text('Start: ${_formatTime(_startTime)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: false),
                    child: Text('End: ${_formatTime(_endTime)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _colorOptions.map((color) {
                final isSelected = color.toARGB32() == _selectedColor.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: isSelected ? 18 : 14,
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.existing != null ? 'Save Changes' : 'Add Subject'),
            ),
          ],
        ),
      ),
    );
  }
}