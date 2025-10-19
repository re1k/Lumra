import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/DrawingAndWritingPrompts.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/cooking.dart';
import '../../model/Activity/ActivityModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/PuzzleGame.dart';

// ---------------------------------------------------------------------------
// ActivityController Goal:
// 1. Merging: Show CHATBOT activities + INITIAL non-completed activities permanently.
// 2. 24h Expiry:
//    • CHATBOT docs: DELETE after 24h.
//    • INITIAL status docs: SOFT-RESET after 24h (keep `wasCompleted:true`).
// 3. Fallback: INITIAL activities that were completed reappear ONLY when all initials are completed.
// 4. Realtime: React to changes in BOTH 'activities' and 'activityStatus'.
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

  int? _lastBand; // 1..4 or 0 (default)
  bool _bandChanged = false;

  void init() {
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    categoryController = TextEditingController();
    timeController = TextEditingController();
  }

  //this is a helper to know if I do not have any chatbot activities, do I show same old initial or did the points change?
  int _bandForPoints(int totalPoints) {
    if (totalPoints >= 5 && totalPoints <= 8) return 1;
    if (totalPoints >= 9 && totalPoints <= 12) return 2;
    if (totalPoints >= 13 && totalPoints <= 16) return 3;
    if (totalPoints >= 17 && totalPoints <= 20) return 4;
    return 0;
  }

  // MAIN Stream: Merges CHATBOT (realtime) with INITIAL (non-completed, sync fetch)
  Stream<List<Activitymodel>> activities$() {
    final uid = authController.currentUser?.uid;
    if (uid == null) {
      return Stream<List<Activitymodel>>.value(const <Activitymodel>[]);
    }

    final controller = StreamController<List<Activitymodel>>();
    StreamSubscription? subStatus;
    StreamSubscription? subUser; //listen to user doc for totalPoints

    // This function recomputes the full merged list each time anything changes.
    Future<void> emitCombined() async {
      final now = DateTime.now();

      // B. Process INITIAL Status docs
      // Instead of deleting expired status docs, we soft-reset them: clear their checked/expiry fields but keep `wasCompleted:true`
      final statusSnap = await db
          .collection('users')
          .doc(uid)
          .collection('activityStatus')
          .where('expireAt', isLessThan: Timestamp.fromDate(now))
          .get();

      if (statusSnap.docs.isNotEmpty) {
        final batch = db.batch();
        for (final doc in statusSnap.docs) {
          batch.update(doc.reference, {
            'isChecked': false,
            'checkedAt': null,
            'expireAt': null,
            // keep 'wasCompleted:true'
          });
        }
        await batch.commit();
      }

      // C. Band (range of points) change handeling:
      // If points band changed, start suppression and delete all initial statuses now (async)
      if (_bandChanged) {
        _bandChanged = false;
      }
      final initialItems = await getinitialActivity();
      controller.add(initialItems);
    }

    subStatus = db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .snapshots()
        .listen((_) => emitCombined());

    subUser = db.collection('users').doc(uid).snapshots().listen((snap) {
      final data = snap.data();
      final int points = (data?['totalPoints'] ?? 0) as int;
      final int band = _bandForPoints(points);
      if (_lastBand != null && _lastBand != band) {
        _bandChanged = true; //flag that band changed
      }
      _lastBand = band; // remember current band
      emitCombined(); // update list now
    });

    // first run
    emitCombined();

    controller.onCancel = () async {
      await subStatus?.cancel();
      await subUser?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  // Loads initial templates once, filtered by the user's points band.
  Future<List<Activitymodel>> _loadInitialTemplates(String uid) async {
    // 1. Get points
    final userDoc = await db.collection('users').doc(uid).get();
    final int totalPoints = userDoc.data()?['totalPoints'] ?? 0;

    // 2. Fetch all templates
    final tplSnap = await db.collection('initialActivities').get();
    final all = tplSnap.docs
        .map((doc) => Activitymodel.fromInitialTemplateDoc(doc))
        .toList();

    // 3. Filter by band (retains the original filtering logic)
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

  // remove the ENTIRE activityStatus subcollection (handles band changes safely)
  Future<void> _removeAllInitialStatus(String uid) async {
    final statusCol = db
        .collection('users')
        .doc(uid)
        .collection('activityStatus');
    final snap = await statusCol.get(); // fetch all
    if (snap.docs.isEmpty) return;

    final batch = db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference); // delete all in a single batch
    }
    await batch.commit();
  }

  // Fetches initial activities (non-realtime): used for the initialItems list in activities$().
  // Logic:
  // PRIMARY list: new or not-expired initials (to display).
  // RESERVE list: previously completed ones (wasCompleted:true).
  // If PRIMARY is empty (ALL initials completed), delete ALL statuses for current templates so the next tick reloads fresh (useful if points band changes).
  Future<List<Activitymodel>> getinitialActivity()
  //({bool fallbackMode = false,})
  async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return [];

    // 1) Load Templates filtered by points
    final candidates = await _loadInitialTemplates(uid);

    // 2) Merge with per-user status
    final statusDocs = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .get();

    final Map<String, Map<String, dynamic>> statusMap = {
      for (final d in statusDocs.docs) d.id: d.data(),
    };

    final primary = <Activitymodel>[]; // fresh initials to show
    final reserve = <Activitymodel>[]; // completed initials

    for (final a in candidates) {
      final status = statusMap[a.id];

      final bool checked = status?['isChecked'] == true;

      final Timestamp? expireTs = status?['expireAt'] as Timestamp?;
      final DateTime? expireAt = expireTs?.toDate();
      final bool expired =
          expireAt != null && expireAt.isBefore(DateTime.now());
      final bool wasCompleted = status?['wasCompleted'] == true;

      // Normal Merging Mode: hide only completed (checked + expired)
      if (checked && expired) continue;

      if (checked && !expired) {
        //still 24h not done so display
        primary.add(a.copyWith(isInitial: true, isChecked: checked));
      } else {
        //unchecked: either because completed or because fresh item
        if (wasCompleted) {
          //completed before
          reserve.add(a.copyWith(isInitial: true, isChecked: false));
        } else //fresh item
        {
          primary.add(a.copyWith(isInitial: true, isChecked: false));
        }
      }
    }

    //Case A: Still have items to display
    if (primary.isNotEmpty) return primary;

    //Case B: All completed, check
    await _removeAllInitialStatus(uid);

    return [];
    // return reserve; //keep something on screen; emitCombined will reload next snapshot
  }

  // Toggles completion for either INITIAL or CHATBOT items.
  // - INITIAL: write per-user status with 24h expiry (soft reset after expiry).
  // - CHATBOT: update and delete after 24h automatically.
  Future<void> toggle(Activitymodel item) async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return;

    final nextChecked = !item.isChecked;
    final now = DateTime.now();
    final expire = now.add(const Duration(hours: 24));

    if (item.isInitial) {
      // INITIAL template -> write per-user status with 24h expiry
      final ref = db
          .collection('users')
          .doc(uid)
          .collection('activityStatus')
          .doc(item.id);

      if (nextChecked) {
        await ref.set({
          'isChecked': true,
          'checkedAt': Timestamp.fromDate(now),
          'expireAt': Timestamp.fromDate(expire),
          'wasCompleted': true,
        }, SetOptions(merge: true));
      } else {
        // Uncheck: clear status and expiry fields
        await ref.set({
          'isChecked': false,
          'checkedAt': null,
          'expireAt': null,
          'wasCompleted': false,
        }, SetOptions(merge: true));
      }
    }
  }

  /// Calculates the number of activities completed in the last 24 hours.
  /// This count naturally works well with the 24-hour expiry logic.
  Future<int> getDailyCompletedCount() async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return 0;

    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    final yesterdayTimestamp = Timestamp.fromDate(yesterday);

    int count = 0;

    // 1. Check completed INITIAL activities (via activityStatus)

    final statusSnap = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: yesterdayTimestamp)
        .get();
    count += statusSnap.docs.length;

    // 2. Check completed CHATBOT activities
    final activitySnap = await db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: yesterdayTimestamp)
        .get();
    count += activitySnap.docs.length;

    return count;
  }

  // to retrive the age of user \
  Future<int> getUserAge() async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return 0;

    final doc = await db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || data['dob'] == null) return 0;

    final Timestamp dobTs = data['dob'];
    final DateTime dob = dobTs.toDate();

    final now = DateTime.now();
    int age = now.year - dob.year;

    // Adjust if birthday hasn't happened yet this year
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    return age;
  }

  /// Calculates the number of activities completed in the last 7 days.
  /// Relies on the 'checkedAt' field which must exist for completed items (before deletion).
  Future<int> getWeeklyCompletedCount() async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return 0;

    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    final lastWeekTimestamp = Timestamp.fromDate(lastWeek);

    int count = 0;
    // for cooking activity
    // 1. Check completed INITIAL activities (via activityStatus)

    final statusSnap = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: lastWeekTimestamp)
        .get();
    count += statusSnap.docs.length;

    // 2. Check completed CHATBOT activities
    final activitySnap = await db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: lastWeekTimestamp)
        .get();
    count += activitySnap.docs.length;

    return count;
  }

  //added this for timer:
  void onActivityTimeTap(Activitymodel item, BuildContext context) {
    final time = item.time.trim();
    if (time.isEmpty) return;

    // Extract integer minutes
    final match = RegExp(r'(\d+)').firstMatch(time);
    final minutes = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;

    if (minutes <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid time value')));
      return;
    }

    // Action differs by category
    final title = item.title.toLowerCase().trim();

    if (title.contains('large puzzle') ||
        title.contains('flash memory challenge') ||
        title.contains('brain games')) {
      Get.to(() => const NumberPuzzle());
      //for now nothing until the rest is added
    } else if (title.contains('writing') ||
        title.contains('write') ||
        title.contains('art') ||
        title.contains('drawing') ||
        title.contains('draw') ||
        title.contains('journaling')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: ActivityPrompts(activityTitle: item.title, minutes: minutes),
        ),
      );
      return; // stop further navigation
    } else if (title.contains('cooking')) {
      getUserAge().then((age) {
        Get.to(() => Cooking(userAge: age));
      });
    }
  }
}
