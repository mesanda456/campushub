import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/subject_service.dart';
import '../models/subject.dart';

final subjectServiceProvider = Provider<SubjectService>((ref) {
  return SubjectService();
});

// Streams the current user's subjects live from Firestore.
final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    // No logged-in user yet — return an empty, non-crashing stream.
    return Stream.value([]);
  }

  final subjectService = ref.watch(subjectServiceProvider);
  return subjectService.watchSubjects(user.uid);
});

// Handles add/update/delete actions.
class SubjectController {
  final SubjectService _subjectService;
  final String? _userId;

  SubjectController(this._subjectService, this._userId);

  Future<void> addSubject(Subject subject) async {
    if (_userId == null) return;
    await _subjectService.addSubject(_userId, subject);
  }

  Future<void> updateSubject(Subject subject) async {
    if (_userId == null) return;
    await _subjectService.updateSubject(_userId, subject);
  }

  Future<void> deleteSubject(String subjectId) async {
    if (_userId == null) return;
    await _subjectService.deleteSubject(_userId, subjectId);
  }
}

final subjectControllerProvider = Provider<SubjectController>((ref) {
  final subjectService = ref.watch(subjectServiceProvider);
  final userId = ref.watch(authStateProvider).value?.uid;
  return SubjectController(subjectService, userId);
});