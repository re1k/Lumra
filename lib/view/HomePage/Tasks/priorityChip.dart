import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class PriorityChip extends StatelessWidget {
  final String label;
  final Color color;

  const PriorityChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: 90, // fixed size
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // fill based on priority color
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: tt.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
