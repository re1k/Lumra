import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/FocusRoom/FocusRoomController.dart';
import 'package:lumra_project/model/FocusRoom/FocusRoomModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/FocusRoom/FocusRoomPlant.dart';

class FocusTimerView extends StatefulWidget {
  const FocusTimerView({super.key, required this.plan});
  final FocusSessionPlan plan;

  @override
  State<FocusTimerView> createState() => _FocusTimerViewState();
}

class _FocusTimerViewState extends State<FocusTimerView> {
  late final FocusController c;
  late DateTime _planStartedAt;

  // total length = sum of all segment minutes (focus + breaks)
  int get _totalPlanSeconds =>
      widget.plan.segments.fold<int>(0, (sum, seg) => sum + seg.minutes) * 60;

  double get _overallProgress {
    final elapsed = DateTime.now().difference(_planStartedAt).inSeconds;
    final p = elapsed / _totalPlanSeconds;
    return p.clamp(0.0, 1.0);
  }

  Timer? _ticker;
  int _segIndex = 0; // which segment we’re in
  late DateTime _segmentEndsAt; // wall clock end time for current segment
  bool _haptics = true;

  // derived
  FocusSegment get _seg => widget.plan.segments[_segIndex];
  bool get _isFocus => _seg.phase == 'focus';

  @override
  void initState() {
    super.initState();
    _planStartedAt = DateTime.now();

    c = Get.find<FocusController>();
    _startSegment(0);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startSegment(int index) {
    _segIndex = index;
    // schedule end of segment by wall clock to avoid drift
    _segmentEndsAt = DateTime.now().add(Duration(minutes: _seg.minutes));
    if (_haptics) HapticFeedback.selectionClick();
    setState(() {}); // update labels
  }

  void _onTick(Timer _) {
    final now = DateTime.now();
    if (now.isBefore(_segmentEndsAt)) {
      // just repaint remaining time
      if (mounted) setState(() {});
      return;
    }
    // Segment finished -> move next
    if (_segIndex + 1 < widget.plan.segments.length) {
      _startSegment(_segIndex + 1);
    } else {
      // All done
      _ticker?.cancel();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Great job!'),
          content: Text(
            'You completed ${widget.plan.config.durationMin} minutes '
            'with ${widget.plan.config.breaksCount} break(s).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _endSession(reset: true);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  void _endSession({bool reset = false}) {
    _ticker?.cancel();
    c.endSession(showToast: !reset);
    Navigator.of(context).pop(); // pop timer screen
  }

  Duration _remaining() {
    final now = DateTime.now();
    final diff = _segmentEndsAt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _mmss(Duration d) {
    final total = d.inSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final rem = _remaining();
    final title = _isFocus ? 'Focus' : 'Break';
    final sub = _isFocus
        ? 'Stay with one small task'
        : 'Stretch • Breathe • Water';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Focus Session', style: TextStyle(fontFamily: 'K2D')),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: _haptics ? 'Haptics on' : 'Haptics off',
            onPressed: () => setState(() => _haptics = !_haptics),
            icon: Icon(_haptics ? Icons.vibration : Icons.do_not_disturb_on),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(BSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Phase badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isFocus
                      ? BColors.primary.withOpacity(.08)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _isFocus
                        ? BColors.primary.withOpacity(.25)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isFocus ? BColors.primary : Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),

              // Plant growth
              PlantGrower(progress: _overallProgress, isFocus: _isFocus),

              const SizedBox(height: 8),

              const Spacer(),

              // Big time
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _mmss(rem),
                  style: const TextStyle(
                    fontFamily: 'K2D',
                    fontSize: 96,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const Spacer(),

              // Progress dots for segments
              Wrap(
                spacing: 8,
                children: List.generate(widget.plan.segments.length, (i) {
                  final s = widget.plan.segments[i];
                  final focus = s.phase == 'focus';
                  final active = i == _segIndex;
                  return Container(
                    width: active ? 16 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active
                          ? (focus ? BColors.primary : Colors.black54)
                          : Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // End session
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('End session?'),
                        content: const Text('You can resume later anytime.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Continue'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('End'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) _endSession();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red.shade400),
                  ),
                  child: Text(
                    'End Session',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
