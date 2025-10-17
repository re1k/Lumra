import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
class LiquidTimer extends StatefulWidget {
  final Duration duration;

  const LiquidTimer({super.key, required this.duration});

  @override
  State<LiquidTimer> createState() => _LiquidTimerState();
}

class _LiquidTimerState extends State<LiquidTimer> {
  Timer? _ticker;
  late int _remaining;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration.inSeconds;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_isRunning || _remaining <= 0) return;
    setState(() => _isRunning = true);

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _isRunning = false;
        });
      } else {
        setState(() {
          _remaining -= 1;
        });
      }
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
  }

  void _restart() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.duration.inSeconds;
      _isRunning = false;
    });
    _start();
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
            // AppBar
            BAppBarTheme.createHeader(
              context: context,
              title: 'Timer',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          LiquidCircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            valueColor: AlwaysStoppedAnimation(
                                BColors.secondry.withOpacity(
                                0.3,
                              )),
                            backgroundColor: BColors.lightGrey,
                            borderColor: BColors.primary,
                            borderWidth: 4.0,
                          ),
                               Center(
                                child: Text(
                                _format(_remaining),
                                style: const TextStyle(
                                fontFamily: 'K2D',
                                fontSize: BSizes.fontSizeLg,
                                 fontWeight: FontWeight.bold,
                                  color: BColors.black,
                                   ),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isRunning ? _pause : _start,
                          icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                          label: Text(_isRunning ? 'Stop' : 'Start'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: BColors.primary),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _restart,
                          icon:
                              const Icon(Icons.restart_alt, color: BColors.primary),
                          label: const Text(
                            'Restart',
                            style: TextStyle(color: BColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
