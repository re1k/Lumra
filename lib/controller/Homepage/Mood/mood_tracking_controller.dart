import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // for date formatting (yyyy-MM-dd)
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'dart:async';

class MoodTrackingController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  String get getCurrentUserId => _userId;
  Timer? _periodicTimer;

  void startPeriodicCheck() {
    _periodicTimer?.cancel();

    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      print(" Checking periodically if 24 hours passed...");
      await checkAndResetIfNeeded();
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userMoodStream() {
    return _userDoc.snapshots();
  }

  String get _userId {
    final user = _authController.currentUser;
    if (user == null) throw Exception("No user is logged in.");
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  String _todayString([DateTime? date]) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(date ?? DateTime.now());
  }

  // -------------------------------------------------------------
  //  INITIALIZATION LOGIC
  // -------------------------------------------------------------

  // to get the daily mood
  Future<int> getTodayMood() async {
    final doc = await _userDoc.get();

    if (doc.exists) {
      final data = doc.data()!;
      final hasDaily = data.containsKey('dailyMood');
      if (hasDaily) {
        final chosen = data['MoodChosenToday'] ?? false;
        return chosen ? data['dailyMood'] ?? 3 : 3;
      }
    }

    await _userDoc.set({
      'dailyMood': 3,
      'MoodChosenToday': false,
    }, SetOptions(merge: true));

    return 3; // no choice
  }

  // -------------------------------------------------------------
  //  USER INTERACTION
  // -------------------------------------------------------------

  // user click the mood
  Future<void> setTodayMood(int moodValue) async {
    await checkAndResetIfNeeded();

    final doc = await _userDoc.get();
    final data = doc.data() ?? {};

    if (!data.containsKey(
          'firstMoodBaseline',
        ) && //  store the base line in case the user does not have a weekly storge to compare
        !data.containsKey('weeklyMood')) {
      await _userDoc.set({
        'firstMoodBaseline': _todayString(),
      }, SetOptions(merge: true));
    }

    // set the user mood

    await _userDoc.set({
      'dailyMood': moodValue,
      'MoodChosenToday': true,
    }, SetOptions(merge: true));

    // delete the base line (no need if there is a weekly value )
    final updatedDoc = await _userDoc.get();
    if (updatedDoc.data()?['weeklyMood'] != null &&
        updatedDoc.data()?['firstMoodBaseline'] != null) {
      await _userDoc.update({'firstMoodBaseline': FieldValue.delete()});
    }
  }

  // -------------------------------------------------------------
  //  DAILY RESET LOGIC
  // -------------------------------------------------------------

  Future<void> resetDailyMood() async {
    await _userDoc.set({
      'dailyMood': 3,
      'MoodChosenToday': false,
    }, SetOptions(merge: true));
  }

  // -------------------------------------------------------------
  // WEEKLY HANDLING
  // -------------------------------------------------------------

  /// Add today’s mood to the weekly list
  Future<void> _addToWeekly(int moodValue) async {
    final doc = await _userDoc.get();

    final now = DateTime.now();
    final todayStr = _todayString(now);

    if (!doc.exists) {
      await _userDoc.set({
        'weeklyMood': {
          'days': [moodValue],
          'lastAdded': todayStr,
        },
      }, SetOptions(merge: true));
      return;
    }

    final data = doc.data()!;
    final weekly = data['weeklyMood'] ?? {'days': [], 'lastAdded': todayStr};
    final List<int> days = List<int>.from(weekly['days'] ?? []);

    days.add(moodValue);

    await _userDoc.set({
      'weeklyMood': {'days': days, 'lastAdded': todayStr},
    }, SetOptions(merge: true));
  }

  // for the dashboard
  Future<List<int>> getWeeklyArray() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return [];

    final data = doc.data()!;
    final weekly = data['weeklyMood'] ?? {'days': []};
    final days = List<int>.from(weekly['days'] ?? []);

    if (days.length >= 7) {
      await _userDoc.set({
        'weeklyMood': {'days': [], 'lastAdded': _todayString()},
      }, SetOptions(merge: true));
    }

    return days;
  }

  // -------------------------------------------------------------
  // DAILY CHECK — RUN ON APP OPEN
  // -------------------------------------------------------------

  // run every 1 min (contain the cases that will store the weekly value)
  Future<void> checkAndResetIfNeeded() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return;

    final data = doc.data()!;

    final hasWeekly = data.containsKey('weeklyMood');
    final hasBaseline = data.containsKey('firstMoodBaseline');

    List<int> days = [];
    String lastAddedStr;

    // choose the varible that we will use it for the comparision

    if (!hasWeekly && hasBaseline) {
      lastAddedStr = (data['firstMoodBaseline'] as String);
      days = <int>[];
    } else {
      final weeklyData =
          data['weeklyMood'] ?? {'days': [], 'lastAdded': _todayString()};
      days = List<int>.from(weeklyData['days'] ?? []);
      lastAddedStr = weeklyData['lastAdded'] as String? ?? _todayString();
    }

    final now = DateTime.now();

    DateTime? lastAddedDate;
    try {
      lastAddedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(lastAddedStr);
    } catch (e) {
      print(' Invalid lastAdded format ($lastAddedStr). Using today.');
      lastAddedDate = now;
    }

    final lastDay = DateTime(
      lastAddedDate.year,
      lastAddedDate.month,
      lastAddedDate.day,
    );
    final todayDay = DateTime(now.year, now.month, now.day);

    final diffDays = todayDay.difference(lastDay).inDays;

    // the same day there is no change
    if (diffDays <= 0) {
      return;
    }
    // one day (store the previous day)
    else if (diffDays == 1) {
      final yesterdayDoc = await _userDoc.get();
      final yesterdayData = yesterdayDoc.data() ?? {};
      final yesterdayMood = yesterdayData['dailyMood'] ?? 3;

      await _addToWeekly(yesterdayMood);
      // reseat the mood
      await _userDoc.update({
        'weeklyMood.lastAdded': _todayString(now),
        'dailyMood': 3,
        'MoodChosenToday': false,
      });

      // more than one day
    } else if (diffDays > 1) {
      final lastDoc = await _userDoc.get();
      final lastMood = lastDoc.data()?['dailyMood'] ?? 3;
      final now = DateTime.now();

      final isMidnight = now.hour == 0 && now.minute < 5;

      final missed = (diffDays).clamp(0, 365);

      days.add(lastMood);

      if (missed > 1) {
        for (int i = 1; i < missed; i++) {
          days.add(3);
        }
      }

      if (isMidnight) {
        days.add(3);
        await _userDoc.update({
          'weeklyMood.days': days,
          'weeklyMood.lastAdded': _todayString(now),
          'dailyMood': 3,
          'MoodChosenToday': false,
        });
      } else {
        await _userDoc.update({
          'weeklyMood.days': days,
          'weeklyMood.lastAdded': _todayString(now),
          'dailyMood': 3,
          'MoodChosenToday': false,
        });
      }
    }
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    super.onClose();
  }
}
