import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/FocusRoom/FocusInputSheet.dart';

class FocusView extends StatefulWidget {
  const FocusView({super.key});

  @override
  State<FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<FocusView>
    with SingleTickerProviderStateMixin {
  bool started = false;
  int? breaks;
  int? focusMinutes;

  Future<void> _startFlow() async {
    // delay ensures modal bottom sheet opens safely after layout
    await Future.delayed(Duration(milliseconds: 50));

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // helps with large bottom sheets
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.46,
        child: DurationAndBreakSheet(),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      started = true;
      focusMinutes = result['duration'];
      breaks = result['breaks'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              //ANIMATION WHOULD BE HERE to make the button go away then it starts? tried one but its so ugly

               //illustration in here cus the page is so empty

              // Start button
                Positioned(
                  top: 500,
                  left: BSizes.defaultSpace,
                  right: BSizes.defaultSpace,
                  child: SafeArea(
                    child: Center(
                      child: GestureDetector(
                        onTap: _startFlow,
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                          horizontal: BSizes.sm + 2,
                          vertical: BSizes.md,
                        ),
                           decoration: BoxDecoration(
                          color: BColors.primary,
                          borderRadius: BorderRadius.circular(
                            BSizes.borderRadiusLg,
                          ),
                        ),
                          child: const Text(
                            'start a focus session',
                            style: TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeMd,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
