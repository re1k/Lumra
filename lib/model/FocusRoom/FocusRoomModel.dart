import 'package:flutter/foundation.dart';

@immutable
class FocusSegment {
  final String phase; // 'focus' or 'break'
  final int minutes;

  const FocusSegment({required this.phase, required this.minutes});

  @override
  String toString() => 'FocusSegment(phase: $phase, minutes: $minutes)';
}

/// Session configuration chosen by the user
@immutable
class FocusSessionConfig {
  final int durationMin; // total duration <= 240, cus 4 hours = 240 min
  final int breaksCount; // number of 5 min breaks

  const FocusSessionConfig({
    required this.durationMin,
    required this.breaksCount,
  });

  FocusSessionConfig copyWith({int? durationMin, int? breaksCount}) =>
      FocusSessionConfig(
        durationMin: durationMin ?? this.durationMin,
        breaksCount: breaksCount ?? this.breaksCount,
      );
}

/// A planned session
@immutable
class FocusSessionPlan {
  final FocusSessionConfig config;
  final List<FocusSegment> segments;

  const FocusSessionPlan({required this.config, required this.segments});

  int get totalMinutes => segments.fold(0, (sum, s) => sum + s.minutes);

  @override
  String toString() =>
      'FocusSessionPlan(total: $totalMinutes, segments: $segments)';
}
