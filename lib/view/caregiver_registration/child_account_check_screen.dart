import 'package:flutter/material.dart';
import 'package:lumra_project/view/HomePage/adhdHomePage.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/adhd_registration/widgets/next_button.dart';
import 'package:lumra_project/view/caregiver_registration/permission_screen.dart';
import 'package:lumra_project/view/adhd_registration/name_screen.dart';
import 'package:get/get.dart';

class ChildAccountCheckScreen extends StatefulWidget {
  const ChildAccountCheckScreen({super.key});

  @override
  State<ChildAccountCheckScreen> createState() =>
      _ChildAccountCheckScreenState();
}

class _ChildAccountCheckScreenState extends State<ChildAccountCheckScreen> {
  late CaregiverController _controller;

  @override
  void initState() {
    super.initState();
    // Use existing controller if available, otherwise create new one
    if (Get.isRegistered<CaregiverController>()) {
      _controller = Get.find<CaregiverController>();
    } else {
      _controller = Get.put(CaregiverController());
    }
    // Listen to controller changes
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild when controller state changes
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.white,
      appBar: AppBar(
        backgroundColor: BColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar
                  SegmentedProgressBar(currentStep: 2, totalSteps: 4),
                  const SizedBox(height: 32),
                  Text(
                    'Does your child already have an ADHD account?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: BColors.black,
                      fontFamily: 'K2D',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will help us connect you with your child\'s account',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BColors.black,
                      fontFamily: 'K2D',
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Yes Option
                  GestureDetector(
                    onTap: () {
                      _controller.setHasChildAccount(true);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _controller.hasChildAccount == true
                            ? BColors.primary.withValues(alpha: 0.1)
                            : BColors.softGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _controller.hasChildAccount == true
                              ? BColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BColors.darkGrey.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _controller.hasChildAccount == true
                                  ? BColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: _controller.hasChildAccount == true
                                    ? BColors.primary
                                    : BColors.darkGrey,
                                width: 2,
                              ),
                            ),
                            child: _controller.hasChildAccount == true
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Yes, my child has an account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: BColors.black,
                                fontFamily: 'K2D',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // No Option
                  GestureDetector(
                    onTap: () {
                      _controller.setHasChildAccount(false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _controller.hasChildAccount == false
                            ? BColors.primary.withValues(alpha: 0.1)
                            : BColors.softGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _controller.hasChildAccount == false
                              ? BColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BColors.darkGrey.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _controller.hasChildAccount == false
                                  ? BColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: _controller.hasChildAccount == false
                                    ? BColors.primary
                                    : BColors.darkGrey,
                                width: 2,
                              ),
                            ),
                            child: _controller.hasChildAccount == false
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No, I need to create an account for my child',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: BColors.black,
                                fontFamily: 'K2D',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          NextButton(
            onPressed: _controller.hasChildAccount != null
                ? () {
                    if (_controller.hasChildAccount == true) {
                      // Continue to permission screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CaregiverPermissionScreen(),
                        ),
                      );
                    } else if (_controller.hasChildAccount == false) {
                      // Navigate to ADHD registration for child
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Welcomepage(),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
