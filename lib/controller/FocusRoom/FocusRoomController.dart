import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lumra_project/model/FocusRoom/FocusRoomModel.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';

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

  /// Call this when duration changes
  void setDuration(int? minutes) {
    if (minutes == null) {
      selectedDurationMin.value = null;
      validBreakOptions.clear();
      selectedBreaks.value = null;
      return;
    }
    final clamped = minutes.clamp(1, kMaxDurationMin);
    selectedDurationMin.value = clamped;
    _recomputeValidBreaks();
    // If previously selected breaks is no longer valid, clear it.
    if (selectedBreaks.value != null &&
        !validBreakOptions.contains(selectedBreaks.value)) {
      selectedBreaks.value = null;
    }
  }

  /// Call this when number of breaks changes
  void setBreaks(int? b) {
    if (b == null) {
      selectedBreaks.value = null;
      return;
    }
    if (validBreakOptions.contains(b)) {
      selectedBreaks.value = b;
    }
  }

  ///  rule:
  /// For session duration D with b breaks of 5 minutes, average gap must be ≥ 15:
  ///   (D - 5b) / (b + 1) >= 15
  static bool _isBreakCountValid(int durationMin, int b) {
    final gaps = b + 1;
    final gapMinutes = (durationMin - kBreakLenMin * b) / gaps;
    return gapMinutes >= kMinGapMin;
  }

  /// Compute allowed break counts for a duration
  static List<int> computeValidBreakCounts(int durationMin) {
    final maxB = max(0, durationMin ~/ (kBreakLenMin + kMinGapMin));
    // Iterate safely up to durationMin/5 just in case
    final hardMax = durationMin ~/ kBreakLenMin;
    final limit = min(maxB + 8, hardMax); // a small buffer
    final out = <int>[];
    for (int b = 0; b <= limit; b++) {
      if (_isBreakCountValid(durationMin, b)) out.add(b);
    }
    return out;
  }

  void _recomputeValidBreaks() {
    final d = selectedDurationMin.value;
    if (d == null) {
      validBreakOptions.clear();
      return;
    }
    validBreakOptions.assignAll(computeValidBreakCounts(d));
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
}
