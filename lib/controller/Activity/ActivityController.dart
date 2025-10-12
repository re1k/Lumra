import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/Activity/ActivityModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

// (READ THIS FIRST)
// Goal:
// 1- Show per-user (chatbot) activities if any exist. (found in the subcollection)
//   • When the user marks a chatbot item done: keep it visible  until 24h pass, then DELETE it from Firestore.

// 2- If there are NO chatbot activities, show shared initial activities based on the user's points.
//   • When the user marks an initial item done: HIDE IT FOREVER (do not show again),
//     UNLESS there are no chatbot activities (fallback mode), in which case we show
//     initials again as available so the screen isn't empty. IN NEXT SPRINTS we can modify the points based on the user's progress in the dashboard

// Key methods and how they call each other:
// - init(): sets up controllers
// - activities$(): MAIN stream the UI listens to.
//     • Builds the list of chatbot items (and deletes expired ones).
//     • If chatbot list is empty → calls getinitialActivity(fallbackMode: true)
//       to show initial activities even if previously completed.
// - getinitialActivity(): returns shared initial activities, merged with
//                                 per-user status (activityStatus) to enforce
//                                 "hide forever after completion" unless fallback.
// - toggle(item): toggles completion.
//     • For initial activities -> writes/updates users/{uid}/activityStatus/{templateId}.
//     • For chatbot activities -> writes/updates users/{uid}/activities/{docId} with
//       expireAt = now + 24h (deletion handled by activities$()).
// ---------------------------------------------------------------------------

class Activitycontroller {
  final FirebaseFirestore db;
  final AuthController authController = Get.find<AuthController>();

  Activitycontroller(this.db);

  final Activity = Rxn<Activitymodel>();
  final RxBool isChecked = false.obs;

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController timeController;

  // Initializes text controllers and starts watching the current user document.
  void init() {
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    categoryController = TextEditingController();
    timeController = TextEditingController();
  }

  // Streams the user's per-user (chatbot) activities.
  // Keeps completed items visible until 24h pass; then deletes them.
  // If the chatbot list is up empty -> calls getinitialActivity(fallbackMode: true) to show initial activities even if previously completed.
  // Streams chatbot items; if empty, switches to a realtime initials stream.
  Stream<List<Activitymodel>> activities$() async* {
    final uid = authController.currentUser?.uid;
    if (uid == null) {
      yield const <Activitymodel>[];
      return;
    }

    // Listen to chatbot activities in realtime
    await for (final q
        in db
            .collection('users')
            .doc(uid)
            .collection('activities')
            .orderBy('title')
            .snapshots()) {
      final now = DateTime.now();
      final toDelete = <DocumentReference>[];
      final userItems = <Activitymodel>[];

      for (final d in q.docs) {
        final m = Activitymodel.fromUserActivityDoc(d);

        // Delete only AFTER 24h passes (keep visible until then)
        final ts = m.expireAt;
        final isExpired = ts != null && ts.toDate().isBefore(now);
        if (isExpired) {
          toDelete.add(d.reference);
          continue; // don't render expired; we'll delete below
        }

        userItems.add(m);
      }

      // Batch delete expired chatbot docs
      if (toDelete.isNotEmpty) {
        final batch = db.batch();
        for (final ref in toDelete) batch.delete(ref);
        await batch.commit();
      }

      if (userItems.isNotEmpty) {
        // Show chatbot list
        yield userItems;
      } else {
        // Fallback to initials as a realtime stream that updates on toggle
        yield* _initialsStream(uid);
      }
    }
  }

  // Realtime fallback stream for INITIAL templates:
  // - Listens to users/{uid}/activityStatus in realtime
  // - Loads templates (once) based on points/band
  // - Merges and yields whenever status changes
  Stream<List<Activitymodel>> _initialsStream(String uid) async* {
    // Load templates once per fallback session (fast + cheap)
    final templates = await _loadInitialTemplates(uid); // based on points

    // Listen to per-user status changes in realtime
    await for (final statusSnap
        in db
            .collection('users')
            .doc(uid)
            .collection('activityStatus')
            .snapshots()) {
      final Map<String, Map<String, dynamic>> statusMap = {
        for (final d in statusSnap.docs) d.id: d.data(),
      };

      // In fallback we SHOW initials even if previously completed,
      // and we REFLECT the actual checked state so checkbox/strike updates instantly.
      final items = <Activitymodel>[];
      for (final t in templates) {
        final status = statusMap[t.id];
        final bool checked = (status?['isChecked'] ?? false) as bool;
        items.add(
          t.copyWith(
            isInitial: true,
            isChecked: checked, // <- realtime checkmark
          ),
        );
      }

      yield items;
    }
  }

  /// Loads initial templates once, filtered by the user's points band.
  Future<List<Activitymodel>> _loadInitialTemplates(String uid) async {
    // get points
    final userDoc = await db.collection('users').doc(uid).get();
    final int totalPoints = userDoc.data()?['totalPoints'] ?? 0;

    // fetch all templates
    final tplSnap = await db.collection('initialActivities').get();
    final all = tplSnap.docs
        .map((doc) => Activitymodel.fromInitialTemplateDoc(doc))
        .toList();

    // filter by band
    List<Activitymodel> filtered = [];
    if (totalPoints >= 5 && totalPoints <= 8) {
      filtered = all
          .where(
            (a) => [
              'Short Walk',
              'Light Yoga',
              'Small Art',
            ].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 9 && totalPoints <= 12) {
      filtered = all
          .where(
            (a) => [
              'Short Run',
              'Brain Games',
              'Cooking',
            ].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 13 && totalPoints <= 16) {
      filtered = all
          .where(
            (a) => [
              'Team sports',
              'Fun Exercises',
              'Journaling',
            ].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 17 && totalPoints <= 20) {
      filtered = all
          .where(
            (a) => [
              'Advanced Yoga',
              'Large Puzzle',
              'Gardening',
            ].contains(a.title.trim()),
          )
          .toList();
    }

    return filtered.isNotEmpty ? filtered : all;
  }

  // Returns true if the user already has any per-user (chatbot) activities.
  Future<bool> hasActivity() async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return false;

    final snapshot = await db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Fetches shared initial activities based on the user's points,
  // merges them with per-user status (activityStatus), and returns:
  // Normal mode (fallbackMode=false): HIDE FOREVER if previously completed.
  // Fallback mode (fallbackMode=true): SHOW ANYWAY (as available/unchecked), so the list isn't empty when there are no chatbot items.
  // Called by: activities$() when chatbot list is empty.
  Future<List<Activitymodel>> getinitialActivity({
    bool fallbackMode = false,
  }) async {
    final uid = authController.currentUser?.uid;

    // 1) Get the user's points
    final userDoc = await db.collection('users').doc(uid).get();
    final int totalPoints = userDoc.data()?['totalPoints'] ?? 0;

    // 2) Load ALL initial templates
    final tplSnap = await db.collection('initialActivities').get();
    final allTemplates = tplSnap.docs
        .map(
          (doc) => Activitymodel.fromInitialTemplateDoc(doc),
        ) // isInitial=true
        .toList();

    // 3) Filter templates based on the user's points band
    List<Activitymodel> filtered = [];
    if (totalPoints >= 5 && totalPoints <= 8) {
      filtered = allTemplates
          .where(
            (a) => [
              'Short Walk',
              'Light Yoga',
              'Small Art',
            ].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 9 && totalPoints <= 12) {
      filtered = allTemplates
          .where(
            (a) => [
              'Short Run',
              'Brain Games',
              'Cooking',
            ].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 13 && totalPoints <= 16) {
      filtered = allTemplates
          .where(
            (a) => [
              'Team sports',
              'Fun Exercises',
              'Journaling',
            ].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 17 && totalPoints <= 20) {
      filtered = allTemplates
          .where(
            (a) => [
              'Advanced Yoga',
              'Large Puzzle',
              'Gardening',
            ].contains(a.title.trim()),
          )
          .toList();
    }

    final candidates = filtered.isNotEmpty ? filtered : allTemplates;

    // 4) Merge with per-user status (tiny docs keyed by templateId)
    final statusDocs = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus') // status for INITIAL templates
        .get();

    final Map<String, Map<String, dynamic>> statusMap = {
      for (final d in statusDocs.docs) d.id: d.data(),
    };

    final result = <Activitymodel>[];

    for (final a in candidates) {
      final status = statusMap[a.id];
      final bool checked = (status?['isChecked'] ?? false) as bool;

      if (!fallbackMode) {
        // Normal mode: hide forever after completion
        if (checked) continue;

        // Show as available (unchecked)
        result.add(a.copyWith(isInitial: true, isChecked: false));
      } else {
        // Fallback mode: show initials EVEN IF checked,
        // and reflect the actual checked state so the checkbox updates visually.
        result.add(a.copyWith(isInitial: true, isChecked: checked));
      }
    }

    return result;
  }

  // Toggles completion for either INITIAL (shared template) or CHATBOT (per-user) items.
  // INITIAL: writes users/{uid}/activityStatus/{templateId} with isChecked.
  //            (No expireAt needed; we hide forever in normal mode.)
  // CHATBOT: writes users/{uid}/activities/{docId} with isChecked and expireAt=now+24h.
  //            (Visible until 24h passes; deletion handled by activities$().)
  Future<void> toggle(Activitymodel item) async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return;

    final nextChecked = !item.isChecked;

    if (item.isInitial) {
      // INITIAL template -> write per-user status
      final ref = db
          .collection('users')
          .doc(uid)
          .collection('activityStatus')
          .doc(item.id); // templateId as the doc id

      if (nextChecked) {
        final now = DateTime.now();
        final expire = now.add(const Duration(hours: 24)); // <-- added
        await ref.set({
          'isChecked': true,
          'checkedAt': Timestamp.fromDate(now),
          'expireAt': Timestamp.fromDate(expire), // <-- ensure not null
        }, SetOptions(merge: true));
      } else {
        await ref.set({
          'isChecked': false,
          'checkedAt': null,
          'expireAt': null,
        }, SetOptions(merge: true));
      }
    } else {
      // CHATBOT per-user doc → set a 24h expiry time
      final ref = db
          .collection('users')
          .doc(uid)
          .collection('activities')
          .doc(item.id);

      if (nextChecked) {
        final now = DateTime.now();
        final expire = now.add(const Duration(hours: 24));
        await ref.update({
          'isChecked': true,
          'checkedAt': Timestamp.fromDate(now),
          'expireAt': Timestamp.fromDate(
            expire,
          ), // activities$ will delete after expiry
        });
      } else {
        await ref.update({
          'isChecked': false,
          'checkedAt': null,
          'expireAt': null,
        });
      }
    }
  }

  // Jana and layan----------------------------------------------------------
  Future<void> addSuggestedActivity({
    required String title,
    required String category,
    required String description,
    required String time,
  }) async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return;

    // Optional: stable id to avoid duplicates (same title+category)
    final slug =
        '${category.trim().toLowerCase()}__${title.trim().toLowerCase()}'
            .replaceAll(RegExp(r'[^a-z0-9_]+'), '_');

    final ref = db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .doc(slug);

    await ref.set({
      'title': title,
      'category': category,
      'description': description,
      'time': time,
      'isChecked': false,
      'createdAt': FieldValue.serverTimestamp(),
      'expireAt': null, // will be set when user checks
      'isInitial': false, //  so UI knows it's a chatbot item
    }, SetOptions(merge: true));
  }
}
