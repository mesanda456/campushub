import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/assignment_service.dart';
import '../models/assignment.dart';

final assignmentServiceProvider = Provider<AssignmentService>((ref) {
  return AssignmentService();
});

final assignmentsProvider = StreamProvider<List<Assignment>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final assignmentService = ref.watch(assignmentServiceProvider);
  return assignmentService.watchAssignments(user.uid);
});

class AssignmentController {
  final AssignmentService _assignmentService;
  final String? _userId;

  AssignmentController(this._assignmentService, this._userId);

  Future<void> addAssignment(Assignment assignment) async {
    if (_userId == null) return;
    await _assignmentService.addAssignment(_userId, assignment);
  }

  Future<void> updateAssignment(Assignment assignment) async {
    if (_userId == null) return;
    await _assignmentService.updateAssignment(_userId, assignment);
  }

  Future<void> deleteAssignment(String assignmentId) async {
    if (_userId == null) return;
    await _assignmentService.deleteAssignment(_userId, assignmentId);
  }

  Future<void> toggleComplete(Assignment assignment) async {
    if (_userId == null) return;
    final newStatus = assignment.status == AssignmentStatus.completed
        ? AssignmentStatus.pending
        : AssignmentStatus.completed;
    await _assignmentService.updateAssignment(
      _userId,
      assignment.copyWith(status: newStatus),
    );
  }
}

final assignmentControllerProvider = Provider<AssignmentController>((ref) {
  final assignmentService = ref.watch(assignmentServiceProvider);
  final userId = ref.watch(authStateProvider).value?.uid;
  return AssignmentController(assignmentService, userId);
});
