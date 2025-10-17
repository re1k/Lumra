import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class MoodRow extends StatefulWidget {
  const MoodRow({super.key});

  @override
  State<MoodRow> createState() => _MoodRowState();
}

class _MoodRowState extends State<MoodRow> {
  int? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: BSizes.xs, bottom: BSizes.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Make icons smaller on very small screens
          final screenWidth = MediaQuery.of(context).size.width;
          final iconSize = screenWidth < 360 ? 48.0 : 56.0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MoodIcon(
                icon: Icons.sentiment_very_dissatisfied,
                color: const Color(0xFFE57373),
                isSelected: selectedMood == 0,
                onTap: () => setState(() => selectedMood = 0),
                size: iconSize,
              ),
              _MoodIcon(
                icon: Icons.sentiment_dissatisfied,
                color: const Color(0xFFFFB74D),
                isSelected: selectedMood == 1,
                onTap: () => setState(() => selectedMood = 1),
                size: iconSize,
              ),
              _MoodIcon(
                icon: Icons.sentiment_neutral,
                color: const Color(0xFFFFF176),
                isSelected: selectedMood == 2,
                onTap: () => setState(() => selectedMood = 2),
                size: iconSize,
              ),
              _MoodIcon(
                icon: Icons.sentiment_satisfied,
                color: const Color(0xFF81C784),
                isSelected: selectedMood == 3,
                onTap: () => setState(() => selectedMood = 3),
                size: iconSize,
              ),
              _MoodIcon(
                icon: Icons.sentiment_very_satisfied,
                color: const Color(0xFF4CAF50),
                isSelected: selectedMood == 4,
                onTap: () => setState(() => selectedMood = 4),
                size: iconSize,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoodIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const _MoodIcon({
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : BColors.white,
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: isSelected ? color : BColors.grey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
