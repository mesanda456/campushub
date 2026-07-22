import 'package:cloud_firestore/cloud_firestore.dart';

enum Priority { low, medium, high }

enum AssignmentStatus { pending, inProgress, completed }

class Assignment {
  final String id;
  final String title;
  final String? subject;
  final DateTime dueDate;
  final Priority priority;
  final AssignmentStatus status;
  final String? notes;

  Assignment({
    required this.id,
    required this.title,
    this.subject,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.name,
      'status': status.name,
      'notes': notes,
    };
  }

  factory Assignment.fromMap(String id, Map<String, dynamic> map) {
    return Assignment(
      id: id,
      title: map['title'] as String,
      subject: map['subject'] as String?,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      priority: Priority.values.byName(map['priority'] as String),
      status: AssignmentStatus.values.byName(map['status'] as String),
      notes: map['notes'] as String?,
    );
  }

  // Convenience for creating an updated copy without mutating the original.
  Assignment copyWith({AssignmentStatus? status}) {
    return Assignment(
      id: id,
      title: title,
      subject: subject,
      dueDate: dueDate,
      priority: priority,
      status: status ?? this.status,
      notes: notes,
    );
  }
}