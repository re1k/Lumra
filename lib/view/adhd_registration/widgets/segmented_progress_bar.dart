import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class SegmentedProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SegmentedProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? BColors.primary : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
