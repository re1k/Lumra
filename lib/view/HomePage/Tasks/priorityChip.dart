import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final double width;
  final double height;

  const PriorityChip({
    super.key,
    required this.label,
    required this.color,
    this.width = 89,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: width, height: height),
      child: Center(
        child: Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          labelPadding: EdgeInsets.zero,
          label: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: tt.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: BColors.white,
          shape: StadiumBorder(side: BorderSide(color: color, width: 1.5)),
        ),
      ),
    );
  }
}
