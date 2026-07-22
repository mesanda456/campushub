import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/assignment_controller.dart';
import '../models/assignment.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  String _searchQuery = '';
  Priority? _priorityFilter;
  AssignmentStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search assignments...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildPriorityFilter()),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusFilter()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                final filtered = _applyFilters(assignments);

                if (filtered.isEmpty) {
                  return const Center(child: Text('No assignments found.'));
                }

                filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _AssignmentTile(assignment: filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _AssignmentFormSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Assignment> _applyFilters(List<Assignment> assignments) {
    return assignments.where((a) {
      final matchesSearch =
          _searchQuery.isEmpty || a.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPriority = _priorityFilter == null || a.priority == _priorityFilter;
      final matchesStatus = _statusFilter == null || a.status == _statusFilter;
      return matchesSearch && matchesPriority && matchesStatus;
    }).toList();
  }

  Widget _buildPriorityFilter() {
    return DropdownButtonFormField<Priority?>(
      initialValue: _priorityFilter,
      decoration: const InputDecoration(labelText: 'Priority', isDense: true),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...Priority.values.map(
          (p) => DropdownMenuItem(value: p, child: Text(p.name)),
        ),
      ],
      onChanged: (value) => setState(() => _priorityFilter = value),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<AssignmentStatus?>(
      initialValue: _statusFilter,
      decoration: const InputDecoration(labelText: 'Status', isDense: true),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...AssignmentStatus.values.map(
          (s) => DropdownMenuItem(value: s, child: Text(s.name)),
        ),
      ],
      onChanged: (value) => setState(() => _statusFilter = value),
    );
  }
}

class _AssignmentTile extends ConsumerWidget {
  final Assignment assignment;

  const _AssignmentTile({required this.assignment});

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = assignment.status == AssignmentStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) {
            ref.read(assignmentControllerProvider).toggleComplete(assignment);
          },
        ),
        title: Text(
          assignment.title,
          style: isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          'Due: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}'
          '${assignment.subject != null ? ' • ${assignment.subject}' : ''}',
        ),
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _priorityColor(assignment.priority),
            shape: BoxShape.circle,
          ),
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => _AssignmentFormSheet(existing: assignment),
        ),
        onLongPress: () {
          ref.read(assignmentControllerProvider).deleteAssignment(assignment.id);
        },
      ),
    );
  }
}

class _AssignmentFormSheet extends ConsumerStatefulWidget {
  final Assignment? existing;

  const _AssignmentFormSheet({this.existing});

  @override
  ConsumerState<_AssignmentFormSheet> createState() => _AssignmentFormSheetState();
}

class _AssignmentFormSheetState extends ConsumerState<_AssignmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _notesController;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  Priority _priority = Priority.medium;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _subjectController = TextEditingController(text: existing?.subject ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    if (existing != null) {
      _dueDate = existing.dueDate;
      _priority = existing.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final assignment = Assignment(
      id: widget.existing?.id ?? '',
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim().isEmpty
          ? null
          : _subjectController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      status: widget.existing?.status ?? AssignmentStatus.pending,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (widget.existing != null) {
      ref.read(assignmentControllerProvider).updateAssignment(assignment);
    } else {
      ref.read(assignmentControllerProvider).addAssignment(assignment);
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
              widget.existing != null ? 'Edit Assignment' : 'Add Assignment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject (optional)'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text(
                'Due: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: Priority.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (value) => setState(() => _priority = value ?? Priority.medium),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.existing != null ? 'Save Changes' : 'Add Assignment'),
            ),
          ],
        ),
      ),
    );
  }
}