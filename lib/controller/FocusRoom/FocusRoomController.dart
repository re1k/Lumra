import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lumra_project/model/FocusRoom/FocusRoomModel.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 5 MIN TEST CASE ADDED BY JANA
class FocusController extends GetxController {
  /// Reactive state
  final RxnInt selectedDurationMin = RxnInt(); // 15, 25, 45, 60...
  final RxnInt selectedBreaks = RxnInt(); //  0..n (5 min each)
  final RxList<int> validBreakOptions = <int>[].obs;

  /// Current plan
  final Rxn<FocusSessionPlan> currentPlan = Rxn<FocusSessionPlan>();

  /// Limits
  static const int kMaxDurationMin = 240; // 4 hours
  static const int kBreakLenMin = 5; // each break = 5 minutes
  static const int kMinGapMin = 15; // min spacing between breaks

  static bool _isBreakCountValid(int durationMin, int b) {
    // Special-case: allow 30 minutes with 1 break as per product requirement.
    if (durationMin == 30 && b == 1) return true;
    if (durationMin == 5 && (b == 0 || b == 1)) return true; //////////TEST CASE

    final gaps = b + 1;
    final gapMinutes = (durationMin - kBreakLenMin * b) / gaps;
    return gapMinutes >= kMinGapMin;
  }

  static List<int> computeValidBreakCounts(int durationMin) {
    final maxB = max(0, durationMin ~/ (kBreakLenMin + kMinGapMin));
    final hardMax = durationMin ~/ kBreakLenMin;
    final limit = min(maxB + 8, hardMax);

    final out = <int>[];
    for (int b = 0; b <= limit; b++) {
      if (_isBreakCountValid(durationMin, b)) out.add(b);
    }

    // Ensure UI shows 1 break for 30 minutes (even if average-gap math would exclude it)
    if (durationMin == 30 && !out.contains(1)) out.add(1);
    if (durationMin == 5) {
      if (!out.contains(0)) out.add(0);
      if (!out.contains(1)) out.add(1);
    } /////TEST CASE
    out.sort();
    return out;
  }

  void setDuration(int? minutes) {
    if (minutes == null) {
      selectedDurationMin.value = null;
      validBreakOptions.clear();
      selectedBreaks.value = null;
      return;
    }

    final clamped = minutes.clamp(1, kMaxDurationMin);
    selectedDurationMin.value = clamped;

    // Recompute options for this duration
    validBreakOptions.assignAll(computeValidBreakCounts(clamped));

    // Default selection per product rules:
    // 15 min  -> 0 breaks
    // 30 min  -> 1 break
    // else    -> keep previous if still valid; otherwise clear
    if (clamped == 15) {
      selectedBreaks.value = 0;
    } else if (clamped == 30) {
      selectedBreaks.value = validBreakOptions.contains(1) ? 1 : null;
    } else if (clamped == 5) {
      /////////TEST CASE
      selectedBreaks.value = validBreakOptions.contains(1) ? 1 : 0;
    } else {
      if (selectedBreaks.value != null &&
          !validBreakOptions.contains(selectedBreaks.value)) {
        selectedBreaks.value = null;
      }
    }
  }

  void setBreaks(int? b) {
    if (b == null) {
      selectedBreaks.value = null;
      return;
    }
    if (validBreakOptions.contains(b)) {
      selectedBreaks.value = b;
    }
  }

  /// Build a simple alternating plan: Focus / Break / Focus / ...
  /// We distribute the focus time as evenly as possible between breaks (there are b+1 focus blocks)
  FocusSessionPlan buildPlan({
    required int durationMin,
    required int breaksCount,
  }) {
    assert(
      _isBreakCountValid(durationMin, breaksCount),
      'Invalid config: spacing rule not satisfied',
    );
    // TEST ONLY EXCEPTION:
    // For 5 minutes with 1 break : Focus 1, Break 3, Focus 1
    if (durationMin == 5 && breaksCount == 1) {
      return FocusSessionPlan(
        config: FocusSessionConfig(
          durationMin: durationMin,
          breaksCount: breaksCount,
        ),
        segments: const [
          FocusSegment(phase: 'focus', minutes: 1),
          FocusSegment(phase: 'break', minutes: 3),
          FocusSegment(phase: 'focus', minutes: 1),
        ],
      );
    }
    final focusBlocks = breaksCount + 1;
    final totalBreakTime = breaksCount * kBreakLenMin;
    final totalFocusTime = durationMin - totalBreakTime;

    // Even split focus minutes, distribute remainders to the first blocks
    final base = totalFocusTime ~/ focusBlocks;
    int remainder = totalFocusTime % focusBlocks;

    final segments = <FocusSegment>[];
    for (int i = 0; i < focusBlocks; i++) {
      final thisBlock = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      segments.add(FocusSegment(phase: 'focus', minutes: thisBlock));
      if (i < breaksCount) {
        segments.add(const FocusSegment(phase: 'break', minutes: kBreakLenMin));
      }
    }

    return FocusSessionPlan(
      config: FocusSessionConfig(
        durationMin: durationMin,
        breaksCount: breaksCount,
      ),
      segments: segments,
    );
  }

  /// Validate and commit plan
  bool confirmPlan() {
    final d = selectedDurationMin.value;
    final b = selectedBreaks.value;
    if (d == null || b == null) return false;
    if (d > kMaxDurationMin) return false;
    if (!_isBreakCountValid(d, b)) return false;

    currentPlan.value = buildPlan(durationMin: d, breaksCount: b);
    return true;
  }

  /// End / reset current plan (call from "End Session" flow)
  void endSession({bool showToast = true}) {
    currentPlan.value = null;
    // Here you can also cancel timers, clear local state, etc.
    if (showToast) {
      ToastService.info("Session ended", "Nice work, come back anytime!");
    }
  }

  /////////////////////////////DASHBOARD///////////////////////////////////////////////////////////////////////////
  Future<void> recordSession({
    required FocusSessionPlan plan,
    required DateTime startedAt,
    required DateTime endedAt,
    required bool completed, // true = finished all segments
    int? stoppedAtSegmentIndex, // null if completed
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Planned totals
    final plannedMinutes = plan.segments.fold<int>(
      0,
      (s, seg) => s + seg.minutes,
    );
    final plannedSeconds = plannedMinutes * 60;

    // Actual totals
    final actualSeconds = endedAt
        .difference(startedAt)
        .inSeconds
        .clamp(0, plannedSeconds);

    // Optional: how many focus vs break minutes planned (handy for charts)
    final plannedFocusMin = plan.segments
        .where((s) => s.phase == 'focus')
        .fold<int>(0, (s, seg) => s + seg.minutes);
    final plannedBreakMin = plannedMinutes - plannedFocusMin;

    // Flatten segments for analytics later
    final segmentsJson = plan.segments
        .map(
          (s) => {
            'phase': s.phase, // 'focus' | 'break'
            'minutes': s.minutes,
          },
        )
        .toList();

    final now = DateTime.now();

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('focus_sessions')
        .doc(); // auto-id

    await doc.set({
      // identity
      'userId': uid,
      'createdAt':
          now, // server timestamp alternative: FieldValue.serverTimestamp()
      // plan info
      'durationMin': plan.config.durationMin,
      'breaksCount': plan.config.breaksCount,
      'segments': segmentsJson, // planned layout
      // timing
      'startedAt': startedAt,
      'endedAt': endedAt,
      'plannedSeconds': plannedSeconds,
      'actualSeconds': actualSeconds,

      // status
      'completed': completed, // finished all segments?
      'stoppedAtSegmentIndex': stoppedAtSegmentIndex, // for quits
      // quick aggregates for dashboard
      'plannedFocusMin': plannedFocusMin,
      'plannedBreakMin': plannedBreakMin,
    });
  }
}
