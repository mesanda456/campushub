import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/attendance_service.dart';
import '../models/attendance_record.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final attendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final attendanceService = ref.watch(attendanceServiceProvider);
  return attendanceService.watchAttendance(user.uid);
});

class AttendanceController {
  final AttendanceService _attendanceService;
  final String? _userId;

  AttendanceController(this._attendanceService, this._userId);

  Future<void> addRecord(AttendanceRecord record) async {
    if (_userId == null) return;
    await _attendanceService.addRecord(_userId, record);
  }

  Future<void> deleteRecord(String recordId) async {
    if (_userId == null) return;
    await _attendanceService.deleteRecord(_userId, recordId);
  }
}

final attendanceControllerProvider = Provider<AttendanceController>((ref) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  final userId = ref.watch(authStateProvider).value?.uid;
  return AttendanceController(attendanceService, userId);
});