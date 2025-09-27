import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TaskController({required this.userId});

  // Hide expired tasks right away (TTL will delete them later) هو كذا طريقته مايتعامل بالثواني
  //we will cancel the TTL because google cloud doesn’t allow direct billing
  Stream<List<Task>> getTasks() {
    final col = _firestore.collection('users').doc(userId).collection('tasks');

    return col
        .where('expireAt', isGreaterThan: Timestamp.now()) // <— NEW
        .snapshots()
        .map((snap) => snap.docs.map((d) => Task.fromFirestore(d)).toList());
  }

  Future<void> addTask(Task task) async {
    final col = _firestore.collection('users').doc(userId).collection('tasks');

    // Ensure every new task has expireAt = now + 24hours
    final data = task.toFirestore(useServerTimestamp: true);
    data['expireAt'] =
        (data['expireAt'] as Timestamp?) ??
        Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

    await col.add(data);
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

  Future<int> getTaskCount() async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();
    return snap.docs.length;
  }

  Future<int> getOpenTaskCount() async {
    //need it for next sprint
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('isChecked', isEqualTo: false)
        .get();
    return snap.docs.length;
  }
  //ALSO FOR NEXT SPRINT

  Future<int> getActiveTaskCount() async {
    final nowTs = Timestamp.now();
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('expireAt', isGreaterThan: nowTs)
        .get();
    return snap.docs.length;
  }

  // if we want the cap to apply to open tasks only:
  Future<int> getOpenActiveTaskCount() async {
    final nowTs = Timestamp.now();
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('expireAt', isGreaterThan: nowTs)
        .where('isChecked', isEqualTo: false)
        .get();
    return snap.docs.length;
  }
}
