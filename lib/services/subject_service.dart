import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/timetable/models/subject.dart';

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subjectsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('subjects');
  }

  Stream<List<Subject>> watchSubjects(String userId) {
    return _subjectsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Subject.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addSubject(String userId, Subject subject) async {
    await _subjectsRef(userId).add(subject.toMap());
  }

  Future<void> updateSubject(String userId, Subject subject) async {
    await _subjectsRef(userId).doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String userId, String subjectId) async {
    await _subjectsRef(userId).doc(subjectId).delete();
  }
}