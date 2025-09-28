import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/adhd_registration/widgets/next_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CaregiverPermissionScreen extends StatefulWidget {
  const CaregiverPermissionScreen({super.key});

  @override
  State<CaregiverPermissionScreen> createState() =>
      _CaregiverPermissionScreenState();
}

class _CaregiverPermissionScreenState extends State<CaregiverPermissionScreen> {
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
        leading: Padding(
          padding: const EdgeInsets.only(top: 17),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
            onPressed: () => Navigator.pop(context),
          ),
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
                  SegmentedProgressBar(currentStep: 2, totalSteps: 3),
                  const SizedBox(height: 32),
                  Text(
                    'Camera Permission',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: BColors.black,
                      fontFamily: 'K2D',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We need access to your camera to scan QR codes and connect with your child\'s account',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BColors.black,
                      fontFamily: 'K2D',
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Permission Icon
                  // QR Scan Icon
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/scanQR.svg',
                      width: 300,
                      height: 300,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          NextButton(
            onPressed: () async {
              await _controller.handleCameraPermissionRequestWithNavigation(
                context,
              );
            },
          ),
        ],
      ),
    );
  }
}
