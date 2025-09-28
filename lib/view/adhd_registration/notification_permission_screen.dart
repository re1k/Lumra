import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/service/permission_service.dart';
import 'package:lumra_project/view/adhd_registration/onboarding_complete_screen.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
  }

  /// Requests notification permission from the user
  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isRequestingPermission = true;
    });

    try {
      // First check current status
      final isGranted = await PermissionService.checkNotificationPermission();

      if (isGranted) {
        // Permission already granted → navigate immediately without any popup
        if (mounted) {
          setState(() {
            _isRequestingPermission = false;
          });
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const OnboardingCompleteScreen(),
              transitionDuration: Duration.zero,
            ),
          );
        }
        return;
      }

      // Request notification permission
      final status = await PermissionService.requestNotificationPermission();

      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });

        if (status.isGranted) {
          // Permission granted → navigate immediately without any popup
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const OnboardingCompleteScreen(),
              transitionDuration: Duration.zero,
            ),
          );
        } else if (status.isDenied) {
          // Permission denied - show info message and navigate
          _showPermissionResultDialog(
            'Permission Denied',
            'You can enable notifications later in your device settings.',
            isSuccess: false,
          );
        } else if (status.isPermanentlyDenied) {
          // Permission permanently denied - show settings dialog
          _showPermissionResultDialog(
            'Permission Required',
            'Notifications are disabled. Please enable them in your device settings to receive helpful reminders.',
            isSuccess: false,
            showSettingsButton: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });

        // Show error message
        _showPermissionResultDialog(
          'Error',
          'Failed to request notification permission. Please try again.',
          isSuccess: false,
        );
      }
    }
  }

  /// Shows a dialog with the permission result
  void _showPermissionResultDialog(
    String title,
    String message, {
    required bool isSuccess,
    bool showSettingsButton = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BColors.black,
              fontFamily: 'K2D',
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: BColors.black,
              fontFamily: 'K2D',
            ),
          ),
          actions: [
            if (showSettingsButton)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: BColors.primary, fontFamily: 'K2D'),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToNextScreen();
              },
              child: Text(
                isSuccess ? 'Continue' : 'close',
                style: const TextStyle(
                  color: BColors.primary,
                  fontFamily: 'K2D',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigates to the next screen
  void _navigateToNextScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingCompleteScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.white,
      appBar: AppBar(backgroundColor: BColors.white),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Transform.translate(
            offset: const Offset(0, -25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Notification Icon
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    alignment: const Alignment(0, 0.0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: SvgPicture.asset(
                        'assets/images/Bell.svg',
                        width: 270,
                        height: 205,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay on track with reminders',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Helpful notifications to guide you and keep you on track',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Buttons at bottom
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isRequestingPermission
                            ? null
                            : _requestNotificationPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRequestingPermission
                              ? BColors.grey
                              : BColors.primary,
                          foregroundColor: BColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isRequestingPermission
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    BColors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Allow',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: BColors.white,
                                  fontFamily: 'K2D',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToNextScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BColors.softGrey,
                          foregroundColor: BColors.darkGrey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide.none,
                        ),
                        child: const Text(
                          'Not Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: BColors.darkGrey,
                            fontFamily: 'K2D',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
