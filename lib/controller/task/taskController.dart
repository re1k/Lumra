import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TaskController({required this.userId});

  Stream<List<Task>> getTasks() {
    final col = _firestore.collection('users').doc(userId).collection('tasks');
    return col.snapshots().map(
      (snap) => snap.docs.map((d) => Task.fromFirestore(d)).toList(),
    );
  }

  Future<void> addTask(Task task) async {
    final col = _firestore.collection('users').doc(userId).collection('tasks');
    await col.add(task.toFirestore(useServerTimestamp: true));
  }

  /// When checked -> priority becomes 'done'.
  /// When unchecked -> priority becomes the doc's basePriority (previous priority).
  Future<void> updateTaskStatus(String taskId, bool isChecked) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId);

    final snap = await docRef.get();
    final data = snap.data() as Map<String, dynamic>? ?? {};

    final currentPriority = (data['priority'] as String?) ?? 'low';
    final basePriority = (data['basePriority'] as String?) ?? currentPriority;

    final newPriority = isChecked ? 'done' : basePriority;

    await docRef.update({
      'isChecked': isChecked,
      'priority': newPriority,
      'basePriority': basePriority,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Counts *all* tasks (done + not done).
  Future<int> getTaskCount() async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();
    return snap.docs.length;
  }

  /// Counts only tasks that are not marked as done.( future sprint)
  Future<int> getOpenTaskCount() async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('isChecked', isEqualTo: false)
        .get();
    return snap.docs.length;
  }
}
