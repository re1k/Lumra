import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lumra_project/model/user_model.dart';
import 'package:lumra_project/controller/Registration/registration_controller.dart';
import 'package:lumra_project/controller/Registration/name_controller.dart';
import 'package:lumra_project/service/auth_signup.dart';
import 'package:lumra_project/service/permission_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/view/caregiver_registration/camera_scan_screen.dart';
import 'package:lumra_project/view/caregiver_registration/verified_screen.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class CaregiverController extends ChangeNotifier {
  UserModel _user = UserModel();
  bool? _hasChildAccount;
  bool _cameraPermissionGranted = false;
  String? _scannedQRCode;

  bool isScanning = true;
  bool hasPermission = false;
  bool isProcessing = false;
  String? lastProcessedCode;
  String? _lastErrorMessage;
  bool _isShowingErrorDialog = false;

  CaregiverController() {
    // Initialize scanning state
    isScanning = true;
    hasPermission = false;
    isProcessing = false;
    lastProcessedCode = null;
    _lastErrorMessage = null;
    _isShowingErrorDialog = false;
  }

  UserModel get user => _user;
  bool? get hasChildAccount => _hasChildAccount;
  bool get cameraPermissionGranted => _cameraPermissionGranted;
  String? get scannedQRCode => _scannedQRCode;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get isShowingErrorDialog => _isShowingErrorDialog;

  void setHasChildAccount(bool hasAccount) {
    _hasChildAccount = hasAccount;
    notifyListeners();
  }

  void setCameraPermission(bool granted) {
    _cameraPermissionGranted = granted;
    notifyListeners();
  }

  void setScannedQRCode(String qrCode) {
    _scannedQRCode = qrCode;
    _user = _user.copyWith(linkedUserId: qrCode);
    notifyListeners();
  }

  Future<bool> validateAndCreateAccount(String linkedUserId) async {
    try {
      // Check if this userId is already linked to another account
      final QuerySnapshot existingLinks = await FirebaseFirestore.instance
          .collection('users')
          .where('linkedUserId', isEqualTo: linkedUserId)
          .get();

      if (existingLinks.docs.isNotEmpty) {
        throw Exception('This account is already linked to another user.');
      }

      // If validation passes, create the caregiver account
      return await createCaregiverAccount(linkedUserId);
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('already linked')) {
        throw Exception('This account is already linked to another user.');
      } else if (e.toString().contains('network')) {
        throw Exception(
          'Network error. Please check your connection and try again.',
        );
      } else {
        throw Exception(
          'An error occurred: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<bool> createCaregiverAccount(String linkedUserId) async {
    try {
      // Get the collected data from controllers
      final regController = Get.find<RegistrationController>();
      final nameController = Get.find<NameController>();

      // Create caregiver and set linkedUserId in one call
      await FirebaseAuthService.createCaregiverAccountWithLink(
        email: regController.emailController.text.trim().toLowerCase(),
        password: regController.passwordController.text,
        name: nameController.nameController.text,
        gender: regController.gender ?? '',
        dob: regController.dob,
        linkedUserId: linkedUserId,
      );

      return true;
    } catch (e) {
      throw Exception('Error creating account: $e');
    }
  }

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      return FirebaseAuth.instance.currentUser?.emailVerified == true;
    } catch (e) {
      throw Exception('Error checking verification: $e');
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Error sending verification email: $e');
    }
  }

  /// Check if email is available for registration
  Future<bool> checkEmailAvailability(String email) async {
    try {
      final normalized = email.trim().toLowerCase();

      // Try to create a temporary account to check email availability
      // This is the same approach as ADHD User but we'll delete the account immediately
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: normalized,
            password: 'temp_password_123!', // Temporary password
          );

      // If we get here, the email is available, so delete the temporary account
      await userCredential.user?.delete();

      // Email is available
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Email is already in use - same as ADHD User
        return false;
      } else {
        // Other Firebase error
        throw Exception('Error checking email availability: ${e.message}');
      }
    } catch (e) {
      // Other errors
      throw Exception('Error checking email availability: $e');
    }
  }

  Future<Map<String, dynamic>> validateEmailForRegistration(
    String email,
  ) async {
    try {
      // Check if email is available
      final bool emailAvailable = await checkEmailAvailability(email.trim());

      if (emailAvailable) {
        return {'success': true, 'error': null};
      } else {
        return {'success': false, 'error': 'This email is already in use'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error checking email availability'};
    }
  }

  Future<bool> checkCameraPermissionAndInit() async {
    final isGranted = await PermissionService.checkCameraPermission();
    if (isGranted) {
      hasPermission = true;
      notifyListeners();
      return true;
    } else {
      hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> onDetectQRCode(String? code) async {
    if (isScanning && !isProcessing && code != null) {
      // Ignore duplicate immediate scans of the same code
      if (lastProcessedCode != null && lastProcessedCode == code) {
        return;
      }
      lastProcessedCode = code;
      isScanning = false;
      isProcessing = true;
      notifyListeners();

      try {
        // Extract LinkedUserId from the scanned barcode
        final linkedUserId =
            code; // The barcode contains the LinkedUserId directly

        // Store the scanned QR code in the controller
        setScannedQRCode(code);

        // Validate and create caregiver account
        await validateAndCreateAccountFromScan(linkedUserId);
      } catch (e) {
        // Reset scanning state on error to allow retry
        isScanning = true;
        isProcessing = false;
        lastProcessedCode = null;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<bool> validateAndCreateAccountFromScan(String linkedUserId) async {
    try {
      // Add timeout to prevent hanging
      final success = await validateAndCreateAccount(linkedUserId).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      if (success) {
        isProcessing = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      isProcessing = false;
      // Allow a clean re-scan
      isScanning = true;
      lastProcessedCode = null;
      notifyListeners();
      rethrow;
    }
  }

  void resetScanningForError() {
    print('Resetting scanning state - isScanning: true, isProcessing: false');
    isScanning = true;
    isProcessing = false;
    lastProcessedCode = null;
    _lastErrorMessage = null; // Clear error message
    _isShowingErrorDialog = false; // Clear error dialog flag
    // Also reset the scanner state
    hasPermission = true; // Keep permission as true
    notifyListeners();
  }

  void clearErrorMessage() {
    _lastErrorMessage = null;
    notifyListeners();
  }

  void setShowingErrorDialog(bool showing) {
    _isShowingErrorDialog = showing;
    notifyListeners();
  }

  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        hasPermission = true;
        notifyListeners();
        return true;
      } else {
        hasPermission = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> validateAndCreateAccountFromBarcode(String linkedUserId) async {
    try {
      // ONLY check if this barcode is already linked to another account
      final QuerySnapshot existingLinks = await FirebaseFirestore.instance
          .collection('users')
          .where('linkedUserId', isEqualTo: linkedUserId)
          .get();

      if (existingLinks.docs.isNotEmpty) {
        // Barcode is already linked to another account
        isProcessing = false;
        notifyListeners();
        throw Exception('This QR code is already linked to another account.');
      }

      // If barcode validation passes, just store the linkedUserId and return success
      // The account creation will happen later in the flow
      setScannedQRCode(linkedUserId);
      isProcessing = false;
      notifyListeners();
    } catch (e) {
      isProcessing = false;
      // Allow a clean re-scan
      isScanning = true;
      lastProcessedCode = null;
      notifyListeners();
      rethrow;
    }
  }

  // Perform reverse linking after successful caregiver account creation
  Future<void> performReverseLinking(String scannedUserId) async {
    try {
      print('Performing reverse linking for scanned user: $scannedUserId');

      // Get the current caregiver's userId (the one we just created)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found for reverse linking');
      }

      final caregiverUserId = currentUser.uid;
      print('Caregiver userId for reverse linking: $caregiverUserId');

      // Update the scanned user's document with the caregiver's userId
      await FirebaseFirestore.instance
          .collection('users')
          .doc(scannedUserId)
          .update({'linkedUserId': caregiverUserId});

      print('Reverse linking completed successfully');
    } catch (e) {
      print('Error in reverse linking: $e');
      // Don't rethrow here - the caregiver account was already created successfully
      // The reverse linking is an additional step that shouldn't fail the main flow
    }
  }

  Future<bool> handleCreateAccountFlow(
    RegistrationController regController,
    NameController nameController,
  ) async {
    try {
      // Validate email format (local)
      await regController.validateEmailWithFirebase(
        regController.emailController.text,
      );

      // Check if email validation passed
      if (regController.emailError == null) {
        // Check email availability using the same logic as ADHD User
        try {
          final bool emailAvailable = await checkEmailAvailability(
            regController.emailController.text,
          );

          if (emailAvailable) {
            // Email is available, create the caregiver account with the linkedUserId
            try {
              await FirebaseAuthService.createCaregiverAccountWithLink(
                email: regController.emailController.text.trim().toLowerCase(),
                password: regController.passwordController.text,
                name: nameController.nameController.text,
                gender: regController.gender ?? '',
                dob: regController.dob,
                linkedUserId: _scannedQRCode ?? '', // Use the scanned QR code
              );

              // After successful caregiver account creation, perform reverse linking
              if (_scannedQRCode != null) {
                await performReverseLinking(_scannedQRCode!);
              }

              // Register controllers with GetX for access in camera scan screen
              Get.put(nameController);
              Get.put(regController);

              // Save the data
              nameController.saveName();
              regController.saveRegistrationData();

              return true;
            } catch (e) {
              // Handle account creation errors
              if (e.toString().contains('email-already-in-use')) {
                regController.emailError =
                    'The email address is already in use';
              } else {
                regController.emailError = 'Error creating account: $e';
              }
              return false;
            }
          } else {
            // Email is already in use - same error handling as ADHD User
            regController.emailError = 'The email address is already in use';
            return false;
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Set email error in the controller - inline error only
            regController.emailError = 'The email address is already in use';
          } else {
            // Handle other Firebase auth errors
            regController.emailError = e.message ?? 'Authentication error';
          }
          // No popup or snackbar - only inline error handling
          return false;
        } on Exception catch (e) {
          // Handle other exceptions (string codes bubbled up)
          if (e.toString().contains('email-already-in-use')) {
            regController.emailError = 'The email address is already in use';
          } else {
            regController.emailError = 'An error occurred';
          }
          return false;
        }
      }
      // If email validation failed, stay on the same screen
      // The error will be shown in the UI
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> initializeCamera() async {
    try {
      final hasPermission = await checkCameraPermission();
      if (hasPermission) {
        return {'success': true, 'navigate': false};
      } else {
        return {'success': false, 'navigate': true};
      }
    } catch (e) {
      return {'success': false, 'navigate': true, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> onDetectBarcode(String? code) async {
    print('onDetectBarcode called with code: $code');
    print(
      'Current state: isScanning=$isScanning, isProcessing=$isProcessing, isShowingErrorDialog=$_isShowingErrorDialog',
    );

    if (code != null && !_isShowingErrorDialog) {
      // Ignore duplicate immediate scans of the same code
      if (lastProcessedCode != null && lastProcessedCode == code) {
        print('Duplicate code detected, ignoring');
        return {'success': false, 'errorMessage': null};
      }

      print('Processing new barcode: $code');
      lastProcessedCode = code;
      isScanning = false;
      isProcessing = true;
      notifyListeners();

      try {
        // Extract LinkedUserId from the scanned barcode
        final linkedUserId =
            code; // The barcode contains the LinkedUserId directly

        // Validate barcode only (no account creation)
        await validateAndCreateAccountFromBarcode(linkedUserId);
        print('Barcode validation successful');
        return {'success': true, 'errorMessage': null};
      } catch (e) {
        print('Error in barcode validation: $e');
        // Store error message but don't set error dialog flag yet
        _lastErrorMessage = e.toString().replaceFirst('Exception: ', '');
        isProcessing = false;
        // Don't reset isScanning here - keep it false to prevent multiple scans
        // lastProcessedCode stays set to prevent duplicate processing
        notifyListeners();
        return {'success': false, 'errorMessage': _lastErrorMessage};
      }
    }
    print(
      'Barcode detection skipped - code: $code, isShowingErrorDialog: $_isShowingErrorDialog',
    );
    return {'success': false, 'errorMessage': null};
  }

  void showErrorDialog(BuildContext context, String message) {
    print('showErrorDialog called with message: $message');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        print('Building error dialog...');
        return AlertDialog(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: BColors.black,
              fontFamily: 'K2D',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('Error dialog OK button pressed');
                Navigator.of(context).pop();
                // Reset scanning state to allow retry
                resetScanningForError();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: BColors.primary, fontFamily: 'K2D'),
              ),
            ),
          ],
        );
      },
    );
  }

  void showPermissionResultDialog(
    BuildContext context,
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
                navigateToNextScreen(context);
              },
              child: Text(
                isSuccess ? 'Continue' : 'Skip',
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

  void navigateToNextScreen(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const CaregiverCameraScanScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> handleCameraPermissionRequestWithNavigation(
    BuildContext context,
  ) async {
    final result = await handleCameraPermissionRequest();

    if (result['success'] == true && result['navigate'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CaregiverCameraScanScreen(),
        ),
      );
    } else if (result['success'] == false) {
      showPermissionResultDialog(
        context,
        result['title'],
        result['message'],
        isSuccess: false,
        showSettingsButton: result['showSettingsButton'] ?? false,
      );
    }
  }

  Future<void> checkEmailVerificationWithNavigation(
    BuildContext context,
  ) async {
    try {
      final isVerified = await checkEmailVerification();
      if (isVerified) {
        // Email is verified - navigate to next step
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CaregiverVerifiedScreen(),
            ),
          );
        }
      } else {
        // Email is not verified - show popup dialog
        if (context.mounted) {
          showVerificationDialog(context);
        }
      }
    } catch (e) {
      // Handle any errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Not Verified'),
          content: const Text('Your account has not been verified yet.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await resendEmailVerificationWithSnackbar(context);
              },
              child: const Text('Resend Email'),
            ),
          ],
        );
      },
    );
  }

  Future<void> resendEmailVerificationWithSnackbar(BuildContext context) async {
    try {
      await resendVerificationEmail();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void navigateToWelcomePage(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Welcomepage()),
      (route) => false,
    );
  }

  Future<Map<String, dynamic>> handleCameraPermissionRequest() async {
    try {
      // First check current status
      final isGranted = await PermissionService.checkCameraPermission();

      if (isGranted) {
        // Permission already granted
        setCameraPermission(true);
        return {'success': true, 'navigate': true};
      }

      // Request camera permission
      final status = await PermissionService.requestCameraPermission();

      if (status.isGranted) {
        // Permission granted - navigate to camera scan screen
        setCameraPermission(true);
        return {'success': true, 'navigate': true};
      } else if (status.isDenied) {
        // Permission denied - show info message and navigate
        return {
          'success': false,
          'navigate': false,
          'title': 'Permission Denied',
          'message':
              'You can enable camera access later in your device settings.',
          'showSettingsButton': false,
        };
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied - show settings dialog
        return {
          'success': false,
          'navigate': false,
          'title': 'Permission Required',
          'message':
              'Camera access is disabled. Please enable it in your device settings to scan QR codes.',
          'showSettingsButton': true,
        };
      } else {
        return {
          'success': false,
          'navigate': false,
          'title': 'Error',
          'message': 'Failed to request camera permission. Please try again.',
          'showSettingsButton': false,
        };
      }
    } catch (e) {
      // Show error message
      return {
        'success': false,
        'navigate': false,
        'title': 'Error',
        'message': 'Failed to request camera permission. Please try again.',
        'showSettingsButton': false,
      };
    }
  }
}
