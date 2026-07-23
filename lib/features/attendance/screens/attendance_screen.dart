import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_record.dart';
import '../../timetable/controllers/subject_controller.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: attendanceAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text('No attendance records yet. Tap + to log one.'),
            );
          }

          final bySubject = _groupBySubject(records);
          final overallPresent = records.where((r) => r.isPresent).length;
          final overallTotal = records.length;
          final overallPercent = (overallPresent / overallTotal) * 100;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: [
                            PieChartSectionData(
                              value: overallPresent.toDouble(),
                              color: Colors.green,
                              showTitle: false,
                              radius: 30,
                            ),
                            PieChartSectionData(
                              value: (overallTotal - overallPresent).toDouble(),
                              color: Colors.red.shade200,
                              showTitle: false,
                              radius: 30,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${overallPercent.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Overall Attendance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'By Subject',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...bySubject.entries.map((entry) {
                final subjectRecords = entry.value;
                final present = subjectRecords.where((r) => r.isPresent).length;
                final total = subjectRecords.length;
                final percent = (present / total) * 100;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(entry.key),
                    subtitle: Text('$present / $total classes attended'),
                    trailing: Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: percent >= 75 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _LogAttendanceSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, List<AttendanceRecord>> _groupBySubject(List<AttendanceRecord> records) {
    final map = <String, List<AttendanceRecord>>{};
    for (final record in records) {
      map.putIfAbsent(record.subjectName, () => []).add(record);
    }
    return map;
  }
}

class _LogAttendanceSheet extends ConsumerStatefulWidget {
  const _LogAttendanceSheet();

  @override
  ConsumerState<_LogAttendanceSheet> createState() => _LogAttendanceSheetState();
}

class _LogAttendanceSheetState extends ConsumerState<_LogAttendanceSheet> {
  String? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  bool _isPresent = true;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_selectedSubject == null) return;

    final record = AttendanceRecord(
      id: '',
      subjectName: _selectedSubject!,
      date: _selectedDate,
      isPresent: _isPresent,
    );

    ref.read(attendanceControllerProvider).addRecord(record);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log Attendance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          subjectsAsync.when(
            data: (subjects) {
              if (subjects.isEmpty) {
                return const Text(
                  'Add subjects in Timetable first to log attendance for them.',
                );
              }
              return DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: subjects
                    .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSubject = value),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error loading subjects: $error'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _pickDate,
            child: Text(
              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Present')),
              ButtonSegment(value: false, label: Text('Absent')),
            ],
            selected: {_isPresent},
            onSelectionChanged: (selection) {
              setState(() => _isPresent = selection.first);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _selectedSubject == null ? null : _submit,
            child: const Text('Log Attendance'),
          ),
        ],
      ),
    );
  }
}