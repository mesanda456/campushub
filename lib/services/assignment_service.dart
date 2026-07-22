import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/assignments/models/assignment.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _assignmentsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('assignments');
  }

  Stream<List<Assignment>> watchAssignments(String userId) {
    return _assignmentsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Assignment.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addAssignment(String userId, Assignment assignment) async {
    await _assignmentsRef(userId).add(assignment.toMap());
  }

  Future<void> updateAssignment(String userId, Assignment assignment) async {
    await _assignmentsRef(userId).doc(assignment.id).update(assignment.toMap());
  }

  Future<void> deleteAssignment(String userId, String assignmentId) async {
    await _assignmentsRef(userId).doc(assignmentId).delete();
  }
}