// lib/view/FocusRoom/FocusInputSheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/controller/FocusRoom/FocusRoomController.dart';
import 'package:lumra_project/view/FocusRoom/FocusRoomWidget.dart';

class DurationAndBreakSheet extends StatelessWidget {
  const DurationAndBreakSheet({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FocusController>();
    final durations = const [5, 15, 30, 45, 60, 90, 120, 180, 240];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BSizes.lg,
          BSizes.lg,
          BSizes.lg,
          BSizes.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Obx(() {
          final selectedDuration = c.selectedDurationMin.value;
          final selectedBreaks = c.selectedBreaks.value;
          final breakOptions = c.validBreakOptions;

          return ListView(
            controller: scrollController, // enables drag/scroll
            shrinkWrap: true,
            children: [
              Text(
                "Choose the focus duration in minutes",
                style: BTextTheme.lightTextTheme.headlineSmall,
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
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => c.setDuration(d), // triggers recompute
                    backgroundColor: BColors.white,
                    selectedColor: BColors.primary.withOpacity(0.9),
                    checkmarkColor: BColors.white,
                  );
                }).toList(),
              ),

              const SizedBox(height: BSizes.SpaceBtwSections),

              Text(
                "Number of breaks",
                style: BTextTheme.lightTextTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // const Text(
              //   "Swipe or tap to select. Breaks are spaced ≥ 15 minutes apart.",
              //   style: TextStyle(fontSize: 12, color: Colors.black54),
              // ),
              const SizedBox(height: 12),

              if (selectedDuration == null)
                const Text(
                  "Pick a duration first.",
                  style: TextStyle(color: Colors.black54),
                )
              else if (breakOptions.isEmpty)
                const Text(
                  "No valid breaks for this duration.",
                  style: TextStyle(color: Colors.black54),
                )
              else if (selectedDuration == 15)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "No need for break, you’ve got this!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SizedBox(
                  height: 220,

                  child: BreaksWheel(
                    options: breakOptions.toList(),
                    initialValue:
                        selectedBreaks ??
                        (breakOptions.isNotEmpty ? breakOptions.first : null),
                    onChanged: (v) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        c.setBreaks(v);
                      });
                    },
                    height: 220,
                    itemExtent: 48,
                    pillRadius: 28,
                  ),
                ),

              const SizedBox(height: BSizes.SpaceBtwSections),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (selectedDuration != null && selectedBreaks != null)
                      ? () {
                          if (c.confirmPlan()) {
                            Navigator.pop(context, {
                              'duration': selectedDuration,
                              'breaks': selectedBreaks,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select valid options.'),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        BSizes.borderRadiusLg,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Set Focus Plan",
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: BSizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
