import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String subjectName;
  final DateTime date;
  final bool isPresent;

  AttendanceRecord({
    required this.id,
    required this.subjectName,
    required this.date,
    required this.isPresent,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
    };
  }

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceRecord(
      id: id,
      subjectName: map['subjectName'] as String,
      date: (map['date'] as Timestamp).toDate(),
      isPresent: map['isPresent'] as bool,
    );
  }
}