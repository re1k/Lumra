import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/FocusRoom/FocusRoomController.dart';
import 'package:lumra_project/model/FocusRoom/FocusRoomModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/FocusRoom/FocusInputSheet.dart';
import 'package:lumra_project/view/FocusRoom/FocusRoomTimer.dart';

class FocusView extends StatefulWidget {
  const FocusView({super.key});

  @override
  State<FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<FocusView>
    with SingleTickerProviderStateMixin {
  final FocusController c = Get.find<FocusController>();

  bool started = false;
  int? breaks;
  int? focusMinutes;

  FocusSessionPlan? plan; // <-- we keep the computed plan here

  Future<void> _startFlow() async {
    // tiny delay so the modal animates smoothly
    await Future.delayed(const Duration(milliseconds: 50));

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          // 70% tall initially, can grow to ..
          initialChildSize: 0.75,
          minChildSize: 0.75,
          maxChildSize: 0.75,
          expand: false,
          builder: (context, scrollController) {
            return DurationAndBreakSheet(scrollController: scrollController);
          },
        );
      },
    );

    if (!mounted || result == null) return;

    final computed = c.currentPlan.value;

    setState(() {
      started = true;
      focusMinutes = result['duration'];
      breaks = result['breaks'];
      plan = computed;
    });
  }

  void _endSession() {
    c.endSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          started = false;
          focusMinutes = null;
          breaks = null;
          plan = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              if (!started)
                Positioned(
                  top: 200,
                  left: BSizes.defaultSpace,
                  right: BSizes.defaultSpace,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/Focus.png',
                          height: 280,
                          width: 280,
                          fit: BoxFit.contain,
                        ),
                        Center(
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
                      ],
                    ),
                  ),
                ),

              // If started and we have a plan, show a simple preview + actions
              if (started && plan != null)
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(BSizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus plan',
                            style: const TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeLg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Here is a summary of your ${plan!.config.durationMin} minutes focus session, whenever your ready!',
                            style: const TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeSm,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Segments list (Focus/Break cycle)
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.only(
                                bottom:
                                    100 +
                                    MediaQuery.of(
                                      context,
                                    ).padding.bottom, // room for action bar
                              ),
                              itemCount: plan!.segments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final s = plan!.segments[i];
                                final isFocus = s.phase == 'focus';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFocus
                                        ? BColors.primary.withOpacity(0.07)
                                        : BColors.lightGrey,
                                    borderRadius: BorderRadius.circular(
                                      BSizes.borderRadiusMd,
                                    ),
                                    border: Border.all(
                                      color: isFocus
                                          ? BColors.primary.withOpacity(0.07)
                                          : const Color.fromARGB(
                                              255,
                                              232,
                                              231,
                                              231,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isFocus ? Icons.timer : Icons.coffee,
                                        size: 20,
                                        color: isFocus
                                            ? BColors.primary
                                            : Colors.black54,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${isFocus ? 'Focus' : 'Break'} — ${s.minutes} min',
                                        style: const TextStyle(
                                          fontFamily: 'K2D',
                                          fontSize: BSizes.fontSizeSm,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              if (started && plan != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 120,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(BSizes.lg, 8, BSizes.lg, 8),
                      decoration: const BoxDecoration(color: BColors.lightGrey),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  //SHOW DO U WANT TO QUIT THE PLAN?
                                  () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        insetPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 24,
                                            ),
                                        title: const Text(
                                          'Quit the Plan?',
                                          style: TextStyle(
                                            fontFamily: 'K2D',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        content: const Text(
                                          'You can start planning another one later, at your convenience!.',
                                          style: TextStyle(
                                            fontFamily: 'K2D',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontFamily: 'K2D',
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: BColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                              minimumSize: const Size(90, 40),
                                            ),
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text(
                                              "Quit",
                                              style: TextStyle(
                                                fontFamily: 'K2D',
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (ok == true) {
                                      //await _saveOnce(completed: false);  ???
                                      _endSession();
                                    }
                                  },
                              //no confirm just go

                              //_endSession
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: BColors.error),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                              ),

                              child: Text(
                                'Quit Plan',
                                style: TextStyle(
                                  fontFamily: 'K2D',
                                  fontSize: BSizes.fontSizeSm,
                                  fontWeight: FontWeight.w600,
                                  color: BColors.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                debugPrint(
                                  '[FocusView] Start Now tapped. plan: ${plan != null}',
                                );
                                if (plan == null) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FocusTimerView(
                                      plan: plan!,
                                      onEnd:
                                          _endSession, // REEM ADD pass reset function
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    BSizes.borderRadiusLg,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Start focusing',
                                style: TextStyle(
                                  fontFamily: 'K2D',
                                  fontSize: BSizes.fontSizeSm,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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
