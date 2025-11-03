import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lumra_project/navigation/nav_config.dart';
import 'package:lumra_project/navigation/nav_controller.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/DrawingAndWritingPrompts.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/SportTimer.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/cooking.dart';
import '../../model/Activity/ActivityModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/PuzzleGame.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/Timer.dart';

// ---------------------------------------------------------------------------
// ActivityController Goal:
// 1. Merging: Show CHATBOT activities + INITIAL non-completed activities permanently.
// 2. 24h Expiry:
//    • CHATBOT docs: DELETE after 24h.
//    • INITIAL status docs: SOFT-RESET after 24h (keep `wasCompleted:true`).
// 3. Fallback: INITIAL activities that were completed reappear ONLY when all initials are completed.
// 4. Realtime: React to changes in BOTH 'activities' and 'activityStatus'.
// 5. Enforce a hard cap of 10 total displayed items (initial + chatbot).
//        If chatbot suggests more than 10, keep the existing 10, prune the extras immediately, and show a one-time Toast when the tab opens.
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
  bool _suppressInitials =
      false; //when I have initial + chatbot activities displayed and the points have changed remove the initial.
  bool _pendingInitialReset = false; // do we need to reset initial statuses?
  //bool _emitting = false; //make sure emitCombined runs one at a time (no overlap)
  bool _initialsCycleDone = false;

  int _overflowEpoch = 0; // increment whenever we prune overflow
  int _lastToastEpochShown = 0;

  static const int _kMaxVisible = 10;
  DateTime? _lastToastAt; // debounce against bursty snapshots
  static const int _toastDebounceMs = 2000; // min 2s between toasts

  // Prevent overlapping emitCombined bodies from racing
  // near your other flags:
  bool _emitting = false; // re-entrancy guard
  bool _emitQueued = false; // run once more if calls arrived while emitting

  StreamController<List<Activitymodel>>? controller;
  StreamSubscription? subActivities;
  StreamSubscription? subStatus;
  StreamSubscription? subUser;

  // Check if Activities tab is currently visible
  bool _isActivitiesTabOpen() {
    if (!Get.isRegistered<NavController>()) return false;
    final nav = Get.find<NavController>();
    final r = nav.role.value;
    if (r == null) return false;
    final items = navConfig[r]!;
    final cur = nav.currentIndex.value;
    return cur >= 0 &&
        cur < items.length &&
        items[cur].label.toLowerCase() == 'activities';
  }

  // Centralized, safe toast (epoch + debounce)
  void _maybeShowOverflowToast() {
    // Only once per epoch
    if (_overflowEpoch <= _lastToastEpochShown) return;

    // Debounce rapid snapshot bursts
    final now = DateTime.now();
    if (_lastToastAt != null &&
        now.difference(_lastToastAt!).inMilliseconds < _toastDebounceMs) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastService.error(
        "Your AI assistant have suggested more activities, but your list has 10 activities. "
        "Finish some first to add new ones.",
      );
    });

    _lastToastEpochShown = _overflowEpoch; //mark this epoch as shown
    _lastToastAt = now; // update debounce clock
  }

  // Call from navbar when Activities tab is tapped
  void onActivitiesTabTapped() {
    _maybeShowOverflowToast(); // show if there’s a new epoch
  }

  void init() {
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    categoryController = TextEditingController();
    timeController = TextEditingController();
    _overflowEpoch = 0;
    _lastToastEpochShown = 0;
    _lastToastAt = null;
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

    // clean/re-init a class-level controller so emitCombined() can add to it
    controller?.close();
    controller = StreamController<List<Activitymodel>>();

    // cancel any previous listeners (no await inside non-async function)
    subActivities?.cancel(); // removed await
    subStatus?.cancel();
    subUser?.cancel();

    subActivities = db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .snapshots()
        .listen((_) => _scheduleEmit());

    subStatus = db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .snapshots()
        .listen((_) => _scheduleEmit());

    subUser = db.collection('users').doc(uid).snapshots().listen((snap) {
      final data = snap.data();
      final int points = (data?['totalPoints'] ?? 0) as int;
      final int band = _bandForPoints(points);
      if (_lastBand != null && _lastBand != band) {
        _bandChanged = true; //flag that band changed
      }
      _lastBand = band; // remember current band
      _scheduleEmit(); // update list now
    });

    // first run
    _scheduleEmit();
    controller!.onCancel = () async {
      await subActivities?.cancel();
      await subStatus?.cancel();
      await subUser?.cancel();
      await controller?.close();
      controller = null;
    };

    return controller!.stream;
  }

  Future<void> _scheduleEmit() async {
    if (_emitting) {
      // someone is running -> queue one rerun
      _emitQueued = true;
      return;
    }
    _emitting = true;
    try {
      await emitCombined(); // first pass
      while (_emitQueued) {
        _emitQueued = false;
        await emitCombined(); //second pass sees the latest snapshot state
      }
    } finally {
      _emitting = false;
    }
  }

  // This function recomputes the full merged list each time anything changes.
  Future<void> emitCombined() async {
    final uid = authController.currentUser!.uid;

    final now = DateTime.now();
    final toDeleteChatbot = <DocumentReference>[];

    // A. Process CHATBOT items
    final q = await db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .orderBy('createdAt', descending: false) // keep oldest first
        .get();

    final userItems = <Activitymodel>[];

    //Keep a parallel list of doc refs to identify overflow for deletion
    final userDocs = <QueryDocumentSnapshot>[];

    for (final d in q.docs) {
      final m = Activitymodel.fromUserActivityDoc(d);

      // Delete CHATBOT docs AFTER 24h passes (based on expireAt)
      final isExpired =
          m.expireAt != null && m.expireAt!.toDate().isBefore(now);
      if (isExpired) {
        toDeleteChatbot.add(d.reference); // Will be deleted below
        continue;
      }

      userItems.add(m);
      userDocs.add(d);
    }
    // if (userItems.isEmpty) {
    //   await _unhideAllHiddenInitials(uid);
    // }

    var initialItems =
        await getinitialActivity(); //now returns full primary, no cap here

    // If nothing to show from initials (likely all hidden), unhide once and reload
    if (initialItems.isEmpty && userItems.isEmpty) {
      initialItems = await getinitialActivity();
      if (initialItems.isEmpty) {
        await _unhideAllHiddenInitials(uid); // unhide any hidden initials
        await _removeAllInitialStatus(uid);
        initialItems = await getinitialActivity();
      }
    }

    //NEW: compute allowed chatbot slots based on how many initials are visible
    final int initialsCount = initialItems.length;
    final int allowedChatbots = (_kMaxVisible - initialsCount).clamp(
      0,
      _kMaxVisible,
    );

    //NEW: Enforce capacity at the DB level for chatbot docs:
    //If chatbot count exceeds its allowed slots, prune the *newest* overflow immediately
    if (userItems.length > allowedChatbots) {
      final overflow = userItems.length - allowedChatbots;
      final toPruneDocs = userDocs.sublist(
        userDocs.length - overflow,
      ); //newest at end
      for (final d in toPruneDocs) {
        toDeleteChatbot.add(d.reference); //not kept in DB
      }
      userItems.removeRange(userItems.length - overflow, userItems.length);
      _overflowEpoch++;
      if (_isActivitiesTabOpen()) {
        _maybeShowOverflowToast();
      }
    }

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
      //points changed
      _suppressInitials = true;
      //mark that we need to reset the initial activities becuase the points changed.
      _pendingInitialReset = true;
    }

    //D- Decide what to show
    List<Activitymodel> toEmit;

    if (_suppressInitials) {
      if (userItems.isNotEmpty) {
        //points changed and there is chatbot items -> only display chatbot items
        final capped = userItems.take(_kMaxVisible).toList();
        controller?.add(capped);

        //ADDED!!!!!!!!!!!!!!!
        _initialsCycleDone = false;
      } else {
        //points changed and no chatbot items -> reset the initial activities and display them
        if (_pendingInitialReset) {
          await _removeAllInitialStatus(uid); // clear old statuses first
          _pendingInitialReset = false;

          //ADDED!!!!!!!!!!!!!!!
          _initialsCycleDone = false;
        }

        final initialItemsFresh = await getinitialActivity();
        _suppressInitials = false;
        final onlyInitials = initialItemsFresh.take(_kMaxVisible).toList();
        controller?.add(onlyInitials); // show initials only
      }
      if (toDeleteChatbot.isNotEmpty) {
        final b = db.batch();
        for (final ref in toDeleteChatbot) b.delete(ref);
        await b.commit();
      }
      //_emitting = false;
      return;
    }

    // E) Normal merge — PRIORITIZE INITIALS, then fill with chatbot up to the remaining slots
    final List<Activitymodel> initialsFirst = initialItems
        .take(_kMaxVisible)
        .toList();
    final remaining = _kMaxVisible - initialsFirst.length;
    final List<Activitymodel> chatbotFill = remaining > 0
        ? userItems.take(remaining).toList()
        : <Activitymodel>[];
    toEmit = [...initialsFirst, ...chatbotFill];

    controller?.add(toEmit);

    // F) Commit deletes (expired + overflow pruned)
    if (toDeleteChatbot.isNotEmpty) {
      final batch = db.batch();
      for (final ref in toDeleteChatbot) batch.delete(ref);
      await batch.commit();
    }
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

    //ADDED!!!!!!!!!!!!!!!!!!!!!!!!
    _initialsCycleDone = true;
    final batch = db.batch();
    for (final d in snap.docs) {
      if (d.data()['hidden'] == true) continue;
      batch.delete(d.reference); // delete all in a single batch
    }
    await batch.commit();
  }

  Future<void> _unhideAllHiddenInitials(String uid) async {
    final col = db.collection('users').doc(uid).collection('activityStatus');
    final hiddenSnap = await col.where('hidden', isEqualTo: true).get();
    if (hiddenSnap.docs.isEmpty) return;
    final batch = db.batch();
    for (final doc in hiddenSnap.docs) {
      batch.update(doc.reference, {
        'hidden': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Fetches initial activities (non-realtime): used for the initialItems list in activities$().
  // Logic:
  // PRIMARY list: new or not-expired initials (to display).
  // RESERVE list: previously completed ones (wasCompleted:true).
  // If PRIMARY is empty (ALL initials completed), delete ALL statuses for current templates so the next tick reloads fresh (useful if points band changes).
  Future<List<Activitymodel>> getinitialActivity() async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return [];

    final candidates = await _loadInitialTemplates(uid);

    final statusCol = db
        .collection('users')
        .doc(uid)
        .collection('activityStatus');
    final statusDocs = await statusCol.get();

    final Map<String, Map<String, dynamic>> statusMap = {
      for (final d in statusDocs.docs) d.id: d.data(),
    };

    final candidateIds = candidates
        .map((a) => a.id)
        .whereType<String>()
        .toSet();
    final existingIds = statusMap.keys.toSet();
    final missingIds = candidateIds.difference(existingIds);
    if (missingIds.isNotEmpty) {
      final batch = db.batch();
      for (final id in missingIds) {
        batch.set(statusCol.doc(id), {
          'isChecked': false,
          'wasCompleted': false,
          'checkedAt': null,
          'expireAt': null,
          'hidden': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }

    final primary = <Activitymodel>[];
    final reserve = <Activitymodel>[];

    for (final a in candidates) {
      final status = statusMap[a.id];
      final bool hidden = status?['hidden'] == true;
      if (hidden) continue;

      final bool checked = status?['isChecked'] == true;

      final Timestamp? expireTs = status?['expireAt'] as Timestamp?;
      final DateTime? expireAt = expireTs?.toDate();
      final bool expired =
          expireAt != null && expireAt.isBefore(DateTime.now());
      final bool wasCompleted = status?['wasCompleted'] == true;

      if (checked && expired) continue;

      if (checked && !expired) {
        primary.add(a.copyWith(isInitial: true, isChecked: checked));
      } else {
        if (wasCompleted) {
          reserve.add(a.copyWith(isInitial: true, isChecked: false));
        } else {
          primary.add(a.copyWith(isInitial: true, isChecked: false));
        }
      }
    }

    if (primary.isNotEmpty) return primary; // return full list (no cap here)

    //await _removeAllInitialStatus(uid);
    return [];
  }

  // Hide initial or delete chatbot activity
  Future<void> setNotInterested(Activitymodel item) async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return;

    final userRef = db.collection('users').doc(uid);

    if (item.isInitial) {
      await userRef.collection('activityStatus').doc(item.id).set({
        'hidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await userRef.collection('activities').doc(item.id).delete();
    }
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
    } else {
      // CHATBOT per-user doc → set a 24h expiry time
      final ref = db
          .collection('users')
          .doc(uid)
          .collection('activities')
          .doc(item.id);

      if (nextChecked) {
        await ref.update({
          'isChecked': true,
          'checkedAt': Timestamp.fromDate(now),
          'expireAt': Timestamp.fromDate(expire),
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
        .where('hidden', isEqualTo: false) //exclude hidden initials from counts
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
        .where(
          'hidden',
          isEqualTo: false,
        ) // exclude hidden initials from counts
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
    final category = item.category.toLowerCase().trim();
    final title = item.title.toLowerCase().trim();

    if (category.contains('sport')) {
      // Open sport timer
      Get.to(() => SportTimer(duration: Duration(minutes: minutes)));
    } else if (title.contains('large puzzle') ||
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
    } else {
      Get.to(() => LiquidTimer(duration: Duration(minutes: minutes)));
    }
  }

  // final RxBool _capacityNoticePending = false.obs; // queued toast

  // void onTabBecameActive() {
  //   // call from Activity tab onReady()
  //   if (_capacityNoticePending.value && !_capacityToastShown) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       ToastService.error(
  //         "Your AI assistant have suggested more activities, but your list has 10 activities. "
  //         "Finish some first to add new ones.",
  //       );
  //     });
  //     _capacityNoticePending.value = false;
  //     _capacityToastShown = true;
  //   }
  // }
}
