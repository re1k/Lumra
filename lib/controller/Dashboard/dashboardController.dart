import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore db;
  final AuthController authController = Get.find<AuthController>();

  DashboardController(this.db);

  /// ADHD user ID linked to this caregiver
  late final String adhdUid;

  /// Reactive counts for UI
  final totalTasks = 0.obs;
  final checkedTasks = 0.obs;

  final RxnInt dailyMood = RxnInt();

  /// NEW by JANA: today's total focus minutes for the ADHD user
  final todayFocusMinutes = 0.obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _moodSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _focusSub; // NEW
  final RxMap<String, double> activityCounts = <String, double>{}.obs;
  final Map<String, String> _globalActivityMap = {};
  Map<String, double> _customActivityCounts = {};
  Map<String, double> _systemActivityCounts = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customActivitySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _systemActivitySub;

  //NEW by Loba for the weekly and daily:
  int? _currentMood; // 1–5 or null
  double _taskPercent = 0; // 0–100
  int _focusMinutesCache = 0; // 0–240
  int _activitiesCount = 0; // total completed

  //composite daily score (0–100) and weekly array (Sun=0..Sat=6)
  final RxDouble dailyScore = 0.0.obs;
  final RxList<double> weeklyScores = List<double>.filled(7, 0.0).obs;

  Timer? _midnightTimer;

  @override
  void onInit() {
    super.onInit();
    _initAll();
  }

  Future<void> _initAll() async {
    final caregiverUid = authController.currentUser!.uid;

    try {
      final snap = await db.collection('users').doc(caregiverUid).get();
      final data = snap.data()!;

      //from your users collection
      adhdUid = data['linkedUserId'] as String;

      // attach all realtime listeners that use adhdUid
      _listenToAdhdTasks();
      _listenToDailyMood();
      _listenToFocusSessions();
      // 3. Start Activity Listeners
      _listenToCustomActivities();
      _listenToSystemActivities();

      await _loadWeeklyScores(); //load existing weeklyDashboard from Firestore
      _scheduleMidnightSave(); // schedule daily saving at midnight
    } catch (e) {
      totalTasks.value = 0;
      checkedTasks.value = 0;
      dailyMood.value = null;
      todayFocusMinutes.value = 0;
    }
  }

  //NEW by Loba: load existing weeklyDashboard array (if any)
  Future<void> _loadWeeklyScores() async {
    final doc = await db.collection('users').doc(adhdUid).get();
    final data = doc.data();
    if (data != null && data['weeklyDashboard'] is List) {
      final raw = data['weeklyDashboard'] as List;
      final arr = List<double>.filled(7, 0.0);
      final len = raw.length < 7 ? raw.length : 7;
      for (int i = 0; i < len; i++) {
        arr[i] = (raw[i] as num).toDouble();
      }
      weeklyScores.assignAll(arr);
    }
  }

  // Realtime listener on /users/{adhdUid}/tasks
  void _listenToAdhdTasks() {
    _tasksSub?.cancel();

    _tasksSub = db
        .collection('users')
        .doc(adhdUid)
        .collection('tasks')
        .snapshots()
        .listen(
          (snap) {
            final docs = snap.docs;

            final int total = docs.length; //total number of tasks
            final int checked =
                docs //checked tasks
                    .where((d) => d.data()['isChecked'] == true)
                    .length;

            totalTasks.value = total;
            checkedTasks.value = checked;

            //NEW: update task progress for scoring
            updateTaskProgress(checked, total);
          },
          onError: (e) {
            totalTasks.value = 0;
            checkedTasks.value = 0;
            updateTaskProgress(0, 0);
          },
        );
  }

  void _listenToDailyMood() {
    _moodSub?.cancel();

    _moodSub = db
        .collection('users')
        .doc(adhdUid) // ADHD user's doc
        .snapshots()
        .listen(
          (snap) {
            final data = snap.data();
            if (data == null || !data.containsKey('dailyMood')) {
              dailyMood.value = null; // hasn't chosen yet
              updateDailyMood(null);
              return;
            }

            // Might be stored as int or num in Firestore, so cast safely
            final val = data['dailyMood'];
            int? moodInt;
            if (val is int) {
              moodInt = val;
            } else if (val is num) {
              moodInt = val.toInt();
            }

            dailyMood.value = moodInt;
            updateDailyMood(moodInt);
          },
          onError: (_) {
            dailyMood.value = null;
            updateDailyMood(null);
          },
        );
  }

  void _listenToFocusSessions() {
    _focusSub?.cancel();

    // compute "today" range
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _focusSub = db
        .collection('users')
        .doc(adhdUid) // ADHD user focus sessions
        .collection('focus_sessions')
        .where('startedAt', isGreaterThanOrEqualTo: startOfDay)
        .where('startedAt', isLessThan: endOfDay)
        .snapshots()
        .listen(
          (snap) {
            int totalSeconds = 0;
            for (final doc in snap.docs) {
              final data = doc.data();
              final seconds = (data['actualSeconds'] ?? 0) as int;
              totalSeconds += seconds;
            }
            final minutes = (totalSeconds / 60).round();
            todayFocusMinutes.value = minutes; //NEW byt Loba
            updateFocusMinutes(minutes);
          },
          onError: (_) {
            todayFocusMinutes.value = 0;
            updateFocusMinutes(0);
          },
        );
  }

  String _getCategoryFromId(String activityId) {
    final String id = activityId.trim();
    switch (id) {
      case '0twbkE4nsbAjGacxFTaI':
        return 'Mindfulness';
      case '5bC5hiEUr7T0IKZ1W2RV':
        return 'Creative';
      case 'opO3WTWQU1aY1CuH6qit':
        return 'Sport';
      case 'Activity4':
        return 'Sport';
      case 'Activity5':
        return 'Learning';
      case 'Activity6':
        return 'Creative';
      case 'Activity7':
        return 'Sport';
      case 'Activity8':
        return 'Sport';
      case 'Activity9':
        return 'Creative';
      case 'Activity10':
        return 'Mindfulness';
      case 'Activity11':
        return 'Learning';
      case 'Activity12':
        return 'mindfulness';
      default:
        return 'other';
    }
  }

  /// Stream 1: User Defined Activities (Directly has category + isChecked)
  void _listenToCustomActivities() {
    _customActivitySub?.cancel();
    _customActivitySub = db
        .collection('users')
        .doc(adhdUid)
        .collection('activities') // chat bot  activities
        .where('isChecked', isEqualTo: true)
        .snapshots()
        .listen((snap) {
          final Map<String, double> tempCounts = {};

          for (var doc in snap.docs) {
            final data = doc.data();
            String category = (data['category'] ?? 'other')
                .toString()
                .toLowerCase();

            if (tempCounts.containsKey(category)) {
              tempCounts[category] = tempCounts[category]! + 1;
            } else {
              tempCounts[category] = 1;
            }
          }

          _customActivityCounts = tempCounts;
          _mergeAndPublishActivityCounts();
        });
  }

  void _listenToSystemActivities() {
    _systemActivitySub?.cancel();

    _systemActivitySub = db
        .collection('users')
        .doc(adhdUid)
        .collection('activityStatus')
        .where('isChecked', isEqualTo: true)
        .snapshots()
        .listen((snap) {
          final Map<String, double> tempCounts = {};

          for (var doc in snap.docs) {
            final String activityId = doc.id;
            String category = _getCategoryFromId(activityId).toLowerCase();

            if (tempCounts.containsKey(category)) {
              tempCounts[category] = tempCounts[category]! + 1;
            } else {
              tempCounts[category] = 1;
            }
          }

          _systemActivityCounts = tempCounts;
          _mergeAndPublishActivityCounts();
        });
  }

  /// Combines counts from both sources and updates the UI
  void _mergeAndPublishActivityCounts() {
    final Map<String, double> merged = {};

    // Add Custom Counts
    _customActivityCounts.forEach((key, value) {
      merged[key] = value;
    });

    // Add System Counts
    _systemActivityCounts.forEach((key, value) {
      if (merged.containsKey(key)) {
        merged[key] = merged[key]! + value;
      } else {
        merged[key] = value;
      }
    });

    activityCounts.value = merged;

    //NEW by Loba: total completed activities for scoring
    final totalCompleted = merged.values.fold<double>(0, (sum, v) => sum + v);
    updateActivitiesCount(totalCompleted.toInt());
  }

  // ----------------- SCORING HELPERS -----------------

  // Mood: 1–5 → 0–1
  double _moodScore() {
    if (_currentMood == null) return 0.0;
    final m = _currentMood!.clamp(1, 5);
    return (m - 1) / 4.0;
  }

  // Tasks: % 0–100 → 0–1
  double _taskScore() {
    if (_taskPercent <= 0) return 0.0;
    return (_taskPercent / 100.0).clamp(0.0, 1.0);
  }

  // Focus: every 30 min = 1 point, max 240 min (8 points) !!CHECK
  double _focusScore() {
    if (_focusMinutesCache <= 0) return 0.0;
    final focusPoints = _focusMinutesCache / 30.0; // 30 min = 1 point
    const maxPoints = 8.0; // 240 / 30
    return (focusPoints / maxPoints).clamp(0.0, 1.0);
  }

  //Activities: every 3 activities = 1 point, cap at 4 points (12 acts)
  double _activityScore() {
    if (_activitiesCount <= 0) return 0.0;
    final activityPoints = _activitiesCount / 3.0;
    const maxPoints = 4.0;
    return (activityPoints / maxPoints).clamp(0.0, 1.0);
  }

  // Combine all into dailyScore (0–100) and update weeklyScores today index
  void _recomputeDailyScore() {
    final mood = _moodScore();
    final task = _taskScore();
    final focus = _focusScore();
    final act = _activityScore();

    final combined = (mood + task + focus + act) / 4.0;
    dailyScore.value = combined * 100.0;

    _updateWeeklyScoresLive(); //so line chart reflects live changes CHECK THIS WITH GIRLS
  }

  // called whenever tasks change
  void updateTaskProgress(int completed, int total) {
    if (total <= 0) {
      _taskPercent = 0;
    } else {
      _taskPercent = (completed / total) * 100.0;
    }
    _recomputeDailyScore();
  }

  // called whenever focus minutes change
  void updateFocusMinutes(int minutes) {
    _focusMinutesCache = minutes.clamp(0, 240);
    _recomputeDailyScore();
  }

  // called whenever mood changes
  void updateDailyMood(int? mood) {
    _currentMood = mood;
    _recomputeDailyScore();
  }

  // called whenever activity counts change
  void updateActivitiesCount(int count) {
    _activitiesCount = count.clamp(0, 1000);
    _recomputeDailyScore();
  }

  // helper: Sunday=0..Saturday=6
  int _dayIndex(DateTime d) {
    return d.weekday % 7;
  }

  // live update weeklyScores for today
  void _updateWeeklyScoresLive() {
    final idx = _dayIndex(DateTime.now());
    if (weeklyScores.length < 7) {
      weeklyScores.assignAll(List<double>.filled(7, 0.0));
    }
    weeklyScores[idx] = dailyScore.value;
    weeklyScores.refresh();
  }

  // save today's score into Firestore weeklyDashboard array at midnight
  Future<void> _saveDailyScoreToWeekArray() async {
    final idx = _dayIndex(DateTime.now());
    final arr = List<double>.from(weeklyScores);
    if (arr.length < 7) {
      final fill = List<double>.filled(7, 0.0);
      final len = arr.length < 7 ? arr.length : 7;
      for (int i = 0; i < len; i++) {
        fill[i] = arr[i];
      }
      weeklyScores.assignAll(fill);
    }

    weeklyScores[idx] = dailyScore.value; // update today's slot
    await db.collection('users').doc(adhdUid).set({
      'weeklyDashboard': weeklyScores,
    }, SetOptions(merge: true));
  }

  // schedule midnight save (and reschedule for next day)
  void _scheduleMidnightSave() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);

    _midnightTimer = Timer(diff, () async {
      await _saveDailyScoreToWeekArray();
      _scheduleMidnightSave(); // schedule again for next midnight
    });
  }

  @override
  void onClose() {
    _tasksSub?.cancel();
    _moodSub?.cancel();
    _focusSub?.cancel();
    _customActivitySub?.cancel();
    _systemActivitySub?.cancel();
    _midnightTimer?.cancel();
    super.onClose();
  }
}
