import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TaskController({required this.userId});
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(userId).collection('tasks');

  // NEW FUNCTION: Searches for tasks with expired 'expireAt' and deletes them.
  Future<void> deleteExpiredTasks() async {
    final now = Timestamp.now();

    // Query for tasks where expireAt is in the past
    final snap = await _col.where('expireAt', isLessThan: now).get();

    if (snap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      // Optional: Log the number of deleted tasks
    }
  }

  // DONOT REMOVE THE COMMENTS
  // Hide expired tasks right away (TTL will delete them later) هو كذا طريقته مايتعامل بالثواني
  // we will cancel the TTL because google cloud doesn’t allow direct billing
  // FREE REORDERING: sort by 'order' only; filter expired in memory.
  Stream<List<Task>> getTasks() {
    // 1. Trigger deletion before fetching (ensures cleanup occurs frequently)
    deleteExpiredTasks();

    return _col.orderBy('order', descending: true).snapshots().map((snap) {
      final now = DateTime.now();
      final all = snap.docs.map(Task.fromFirestore).toList();

      // 2. Filter expired tasks that were not deleted yet (filter in memory)
      return all.where((t) {
        final ts = t.expireAt; // may be null
        if (ts == null) return true;
        return ts.toDate().isAfter(now);
      }).toList();
    });
  }

  Future<void> addTask(Task task) async {
    final data = task.toFirestore(useServerTimestamp: true);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['order'] = DateTime.now().microsecondsSinceEpoch; // higher = higher

    // Ensure expireAt is set to now + 24 hours
    data['expireAt'] =
        (data['expireAt'] as Timestamp?) ??
        Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

    await _col.add(data);
  }

  Future<void> reorderTasks(
    List<Task> tasks,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, moved);

    final batch = _firestore.batch();
    int base = DateTime.now().millisecondsSinceEpoch; // newest at top
    for (int i = 0; i < tasks.length; i++) {
      batch.update(_col.doc(tasks[i].id), {
        'order': base - i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updateTaskStatus(String taskId, bool isChecked) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId);

    final updateData = {
      'isChecked': isChecked,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isChecked) {
      updateData['order'] = -DateTime.now().microsecondsSinceEpoch;
    }

    await docRef.update(updateData);
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
  // ALSO FOR NEXT SPRINT

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

  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}
