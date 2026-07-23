import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/attendance/models/attendance_record.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _attendanceRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('attendance');
  }

  Stream<List<AttendanceRecord>> watchAttendance(String userId) {
    return _attendanceRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addRecord(String userId, AttendanceRecord record) async {
    await _attendanceRef(userId).add(record.toMap());
  }

  Future<void> deleteRecord(String userId, String recordId) async {
    await _attendanceRef(userId).doc(recordId).delete();
  }
}