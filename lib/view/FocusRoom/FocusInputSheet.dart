import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_field_theme.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

class DurationAndBreakSheet extends StatefulWidget {
  const DurationAndBreakSheet({super.key});

  @override
  State<DurationAndBreakSheet> createState() => _DurationAndBreakSheetState();
}

class _DurationAndBreakSheetState extends State<DurationAndBreakSheet> {
  int? selectedDuration;
  int? selectedBreaks;

  final durations = [15, 25, 45, 60];
  final breaks = [1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(BSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Focus duration
          Text(
            "Choose the focus duration in minutes",
            style: BTextTheme.lightTextTheme.headlineSmall
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: durations.map((d) {
              final isSelected = selectedDuration == d;
              return ChoiceChip(
                label: Text(
                  "$d",
                  style: TextStyle(
                    fontFamily: 'K2D',
                    color: isSelected
                        ? Colors.white
                        : Colors.black, // change color when selected
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => selectedDuration = d),
                backgroundColor: BColors.white,
                selectedColor: BColors.primary.withOpacity(0.9),
                checkmarkColor: BColors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: BSizes.SpaceBtwSections),

          // Breaks
          Text(
            "Number of 5-minutes Breaks",
            style: BTextTheme.lightTextTheme.headlineSmall
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: breaks.map((b) {
              final isSelected = selectedBreaks == b;
              return ChoiceChip(
                label: Text(
                  "$b",
                  style: TextStyle(
                    fontFamily: 'K2D',
                    color: isSelected
                        ? Colors.white
                        : Colors.black, // change color when selected
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => selectedBreaks = b),
                labelStyle: const TextStyle(fontFamily: 'K2D'),
                backgroundColor: BColors.white,
                selectedColor: BColors.primary.withOpacity(0.9),
                checkmarkColor: BColors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: BSizes.SpaceBtwSections),

          // Start button
        SizedBox(
  width: double.infinity, // full width
  child: ElevatedButton(
    onPressed: (selectedDuration != null && selectedBreaks != null)
        ? () => Navigator.pop(context, {
              'duration': selectedDuration!,
              'breaks': selectedBreaks!,
            })
        : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: BColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
      ),
    ),
    child: const Text(
      "Start Focusing",
      style: TextStyle(
        fontFamily: 'K2D',
        fontSize: BSizes.fontSizeSm,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
),

          const SizedBox(height: BSizes.SpaceBtwSections),
        ],
      ),
    );
  }
}
