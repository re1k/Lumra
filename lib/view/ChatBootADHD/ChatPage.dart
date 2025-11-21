import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/ChatBoot/baseController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart';

class ChatPage extends StatefulWidget {
  final BaseChatController controller;
  const ChatPage({super.key, required this.controller});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: Column(
        children: [
          // Unified header: Stack with wave background + header row on top
          SizedBox(
            height:
                MediaQuery.of(context).viewPadding.top +
                BSizes.lg +
                36 +
                30, // Slightly increased wave height for better visual balance
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Background decorative wave (AnimatedWaveClipper) - thin header decoration
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (context, _) {
                      return ClipPath(
                        clipper: _AnimatedWaveClipper(phase: _waveCtrl.value),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [BColors.primary, BColors.secondry],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 2. Header row above the wave
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      BSizes.lg,
                      BSizes.lg,
                      BSizes.lg,
                      BSizes.xs, // Minimal bottom padding for tight header
                    ),
                    child: Row(
                      children: [
                        // Back button with correct shadow/elevation - standard size
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: BColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: BColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: BSizes.sm),
                        // Title - must be visible and above the wave, centered but slightly shifted left
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Text(
                              'Lumra Assistant',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: BColors.black,
                                    fontSize: 28,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chat content below - expands to full vertical space
          Expanded(child: ChatView(controller: widget.controller)),
        ],
      ),
    );
  }
}

// Wave clipper (copied from ChatBootADHD.dart)
class _AnimatedWaveClipper extends CustomClipper<Path> {
  final double phase; // 0..1
  const _AnimatedWaveClipper({required this.phase});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    const waveHeight = 16.0;
    const baseDrop = 12.0;
    final t = phase * 2 * 3.1415926535;

    final shift = (w * 0.12) * (0.5 + 0.5 * sin(t));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - baseDrop);

    final c1 = Offset(
      w * 0.25 + shift * 0.5,
      h - baseDrop - waveHeight * (0.6 + 0.4 * sin(t)),
    );
    final p1 = Offset(w * 0.50, h - baseDrop);

    final c2 = Offset(
      w * 0.75 - shift,
      h - baseDrop + waveHeight * (0.6 + 0.4 * cos(t)),
    );
    final p2 = Offset(w, h - baseDrop);

    path
      ..quadraticBezierTo(c1.dx, c1.dy, p1.dx, p1.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, p2.dx, p2.dy)
      ..lineTo(w, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _AnimatedWaveClipper oldClipper) =>
      oldClipper.phase != phase;
}
