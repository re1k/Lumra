import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class PlantGrower extends StatelessWidget {
  const PlantGrower({
    super.key,
    required this.progress, // 0.0 .. 1.0
    required this.isFocus, // focus = growing state, break = subtle idle pulse
  });

  final double progress;
  final bool isFocus;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    // we might change this approach:
    // choose icon stage by progress
    IconData icon;
    if (p < 0.25) {
      icon = Icons.spa_outlined; // seed / bud
    } else if (p < 0.55) {
      icon = Icons.grass; // sprout
    } else if (p < 0.85) {
      icon = Icons.nature; // small tree
    } else {
      icon = Icons.park_rounded; // big tree
    }

    // scale 0.6 → 1.0 across the whole session
    final scale = 0.6 + (0.4 * p);
    // vertical lift so it rises from pot
    final lift = Tween<double>(begin: 30, end: -6).transform(p);

    // idle pulse on breaks
    final opacity = isFocus
        ? 1.0
        : (0.9 + 0.1 * (1 - (DateTime.now().millisecond % 1000) / 1000));

    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ground / pot shadow
          Positioned(
            bottom: 46,
            child: Container(
              width: 180,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            child: Container(
              width: 160,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63), // clay brown (change ?)
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),

          // plant
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, lift),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  icon,
                  size: 120,
                  color: _lerpColor(
                    const Color(0xFF66BB6A),
                    const Color(0xFF2E7D32),
                    p,
                  ),
                ),
              ),
            ),
          ),

          if (p > 0.7)
            ...List.generate(6, (i) {
              final angle = i * 60.0;
              final rad =
                  40.0 + (p - 0.7) * 40.0; // expand a bit as we near 1.0
              final dx = rad * (i.isEven ? 1 : -1) * 0.2;
              return Positioned(
                bottom: 110,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(dx * (i - 2.5), -5.0 * (i % 3)),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 14 + (p - 0.7) * 10,
                    color: const Color(0xFF66BB6A).withOpacity(0.6),
                  ),
                ),
              );
            }),

          // progress ring
          Positioned(
            top: 0,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: p,
                    strokeWidth: 5,
                    backgroundColor: Colors.black12,
                    color: BColors.primary,
                  ),
                  const Icon(
                    Icons.local_florist,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _lerpColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t.clamp(0.0, 1.0))!;
  }
}
