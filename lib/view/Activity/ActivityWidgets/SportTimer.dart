import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';

class SportTimer extends StatefulWidget {
  /// Pass the exact time you want the timer to count down from.
  final Duration duration;

  const SportTimer({super.key, required this.duration});

  @override
  State<SportTimer> createState() => _SportTimerState();
}

class _SportTimerState extends State<SportTimer>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late int _remaining; // seconds left
  bool _isRunning = false;
  late final AnimationController _lottieCtrl;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration.inSeconds;
    _lottieCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
    _lottieCtrl.dispose();
  }

  void _start() {
    if (_isRunning || _remaining <= 0) return;
    setState(() => _isRunning = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        // hit zero
        t.cancel();
        setState(() {
          _remaining = 0;
          _isRunning = false;
        });
        _lottieCtrl.stop();
      } else {
        setState(() {
          _remaining -= 1;
        });
      }
    });
    if (_lottieCtrl.duration != null) {
      _lottieCtrl.repeat();
    }
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    _lottieCtrl.stop();
  }

  void _restart() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.duration.inSeconds;
      _isRunning = false;
    });
    _lottieCtrl
      ..stop()
      ..value = 0.0;

    _start(); // auto-start after restart; remove this line if you prefer manual start
  }

  String _format(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inSeconds;
    final progress = total == 0 ? 0.0 : (total - _remaining) / total;

    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: SafeArea(
        child: Column(
          children: [
            // New unified header with back button
            BAppBarTheme.createHeader(
              context: context,
              title: 'Sport Timer',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            //do you feel we add title? remove the comment to see how it looks
            // centerTitle: true,
            // title: Text(
            //   "Sport Timer",
            //   style: const TextStyle(
            //     fontFamily: 'K2D',
            //     fontSize: BSizes.fontSizeLg,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //   ),
            // ),
            // Main content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 240,
                            width: 240,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 10,
                              color: BColors.primary,
                              backgroundColor: BColors.secondry.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          Lottie.asset(
                            "assets/animation/sportTimer.json",
                            height: 190,
                            controller: _lottieCtrl,
                            onLoaded: (composition) {
                              _lottieCtrl.duration =
                                  composition.duration; // Capture duration
                              if (!_isRunning) {
                                _lottieCtrl
                                  ..stop()
                                  ..value = 0.0; // Stay still when not running
                              } else {
                                _lottieCtrl.repeat();
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        _format(_remaining),
                        style: const TextStyle(
                          fontFamily: 'K2D',
                          fontSize: BSizes.fontSizeLg,
                          fontWeight: FontWeight.bold,
                          color: BColors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const SizedBox(height: 16),

                      // ---- Controls: Start/Pause (Stop) and Restart
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Start / Stop (Pause)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isRunning ? _pause : _start,
                            icon: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              _isRunning ? 'Stop' : 'Start',
                              style: const TextStyle(
                                fontFamily: 'K2D',
                                fontSize: BSizes.fontSizeMd,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: BColors.primary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _restart,
                            icon: const Icon(
                              Icons.restart_alt,
                              color: BColors.primary,
                            ),
                            label: const Text(
                              'Restart',
                              style: TextStyle(
                                fontFamily: 'K2D',
                                fontSize: BSizes.fontSizeSm,
                                color: BColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
