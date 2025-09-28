import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lumra_project/model/user_model.dart';
import 'package:lumra_project/service/auth_signup.dart';
import 'package:lumra_project/service/permission_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/view/caregiver_registration/camera_scan_screen.dart';
import 'package:lumra_project/view/adhd_registration/notification_permission_screen.dart';
import 'package:lumra_project/view/adhd_registration/onboarding_complete_screen.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class CaregiverController extends ChangeNotifier {
  UserModel _user = UserModel();
  bool? _hasChildAccount;
  bool _cameraPermissionGranted = false;
  String? _scannedQRCode;

  // Store registration data directly in CaregiverController
  String _email = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  String _gender = '';
  DateTime? _dob;

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

  // Getters for registration data
  String get email => _email;
  String get password => _password;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get gender => _gender;
  DateTime? get dob => _dob;

  void setHasChildAccount(bool hasAccount) {
    _hasChildAccount = hasAccount;
    notifyListeners();
  }

  // Methods to store registration data
  void setRegistrationData({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime? dob,
  }) {
    _email = email;
    _password = password;
    _firstName = firstName;
    _lastName = lastName;
    _gender = gender;
    _dob = dob;
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

  /// Save user data after email verification
  /// NOTE: This method is NOT used in the QR code scanning flow.
  /// The QR code scanning flow uses createCaregiverAccountWithLink() directly.
  Future<bool> saveUserDataAfterVerification() async {
    try {
      // Check if we have a scanned QR code (linkedUserId)
      if (_scannedQRCode == null || _scannedQRCode!.isEmpty) {
        throw Exception('No QR code scanned. Please scan the QR code first.');
      }

      // For QR code scanning flow, the account was already created with linkedUserId
      // Just return true since the data is already saved
      return true;
    } catch (e) {
      throw Exception('Failed to save user data: $e');
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

  void resetScanningForError() {
    // Reset only scanning state, keep registration data and permissions
    isScanning = true;
    isProcessing = false;
    lastProcessedCode = null;
    _lastErrorMessage = null; // Clear error message
    _isShowingErrorDialog = false; // Clear error dialog flag
    // Keep permission as true
    hasPermission = true;
    notifyListeners();
  }

  /// Reset controller state for new scanning session
  void resetForNewSession() {
    isScanning = true;
    isProcessing = false;
    lastProcessedCode = null;
    _lastErrorMessage = null;
    _isShowingErrorDialog = false;
    _scannedQRCode = null;
    hasPermission = false;
    _cameraPermissionGranted = false;

    // Clear registration data for new session
    _email = '';
    _password = '';
    _firstName = '';
    _lastName = '';
    _gender = '';
    _dob = null;

    notifyListeners();
  }

  /// Reset only scanning state without clearing registration data
  void resetScanningStateOnly() {
    isScanning = true;
    isProcessing = false;
    lastProcessedCode = null;
    _lastErrorMessage = null;
    _isShowingErrorDialog = false;
    _scannedQRCode = null;
    notifyListeners();
  }

  /// Clear all caregiver registration data (for back navigation or after success)
  void clearAllCaregiverData() {
    // Clear registration data
    _email = '';
    _password = '';
    _firstName = '';
    _lastName = '';
    _gender = '';
    _dob = null;
    _scannedQRCode = null;

    // Reset scanning state
    isScanning = true;
    isProcessing = false;
    lastProcessedCode = null;
    _lastErrorMessage = null;
    _isShowingErrorDialog = false;

    // Reset permissions
    hasPermission = false;
    _cameraPermissionGranted = false;

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
    if (code != null && !_isShowingErrorDialog) {
      // Ignore duplicate immediate scans of the same code
      if (lastProcessedCode != null && lastProcessedCode == code) {
        return {'success': false, 'errorMessage': null};
      }

      // Show loading indicator immediately for any detected code
      lastProcessedCode = code;
      isScanning = false;
      isProcessing = true;
      notifyListeners();

      // Check if scanned value corresponds to a real user doc
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(code)
            .get();
        if (!userDoc.exists) {
          // Not a valid UID → reset and ignore
          isProcessing = false;
          isScanning = true;
          lastProcessedCode = null;
          notifyListeners();
          return {'success': false, 'errorMessage': null};
        }
      } catch (_) {
        // Any error in preflight → reset and ignore
        isProcessing = false;
        isScanning = true;
        lastProcessedCode = null;
        notifyListeners();
        return {'success': false, 'errorMessage': null};
      }

      // Valid UID found - continue with linking process
      try {
        await _processValidUID(code);
        return {'success': true, 'errorMessage': null};
      } catch (e) {
        // Store error message for dialog display
        _lastErrorMessage = e.toString().replaceFirst('Exception: ', '');
        isProcessing = false;
        isScanning = true;
        lastProcessedCode = null;
        notifyListeners();
        return {'success': false, 'errorMessage': _lastErrorMessage};
      }
    }
    return {'success': false, 'errorMessage': null};
  }

  Future<void> _processValidUID(String scannedUID) async {
    // Check Firestore for that UID
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(scannedUID)
        .get();

    final userData =
        userDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final existingLinkedUserId = (userData['linkedUserId'] as String?)?.trim();

    if (existingLinkedUserId != null && existingLinkedUserId.isNotEmpty) {
      // linkedUserId is not empty - do not link, show popup
      // Add a small delay to ensure loading indicator is visible
      await Future.delayed(const Duration(milliseconds: 1000));
      throw Exception('This user is already linked to another account.');
    }

    // linkedUserId is empty - proceed with linking
    // Use stored registration data from CaregiverController
    if (_email.trim().isEmpty ||
        _password.isEmpty ||
        _firstName.trim().isEmpty ||
        _lastName.trim().isEmpty) {
      throw Exception(
        'Registration data is missing. Please restart the registration process.',
      );
    }

    // Create the caregiver account immediately with bidirectional linking
    await FirebaseAuthService.createCaregiverAccountWithLink(
      email: _email.trim().toLowerCase(),
      password: _password,
      firstName: _firstName.trim(),
      lastName: _lastName.trim(),
      gender: _gender,
      dob: _dob,
      linkedUserId: scannedUID,
    );

    // Set the scanned QR code for future reference
    setScannedQRCode(scannedUID);

    isProcessing = false;
    notifyListeners();
  }

  void showErrorDialog(BuildContext context, String message) {
    if (_isShowingErrorDialog) {
      return;
    }
    _isShowingErrorDialog = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
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
                _isShowingErrorDialog = false;
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
    ).then((_) {
      // Ensure flag cleared if dismissed by tapping outside
      if (_isShowingErrorDialog) {
        _isShowingErrorDialog = false;
        resetScanningForError();
      }
    });
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
        // Email is verified - check if we're in QR code scanning flow or email verification flow
        if (_scannedQRCode != null && _scannedQRCode!.isNotEmpty) {
          // QR code scanning flow - account was already created with linkedUserId
          // Navigate directly to notification/onboarding
          if (context.mounted) {
            final granted =
                await PermissionService.checkNotificationPermission();
            if (granted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OnboardingCompleteScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPermissionScreen(),
                ),
              );
            }
          }
        } else {
          // Email verification flow - need to save user data
          try {
            final success = await saveUserDataAfterVerification();
            if (success && context.mounted) {
              final granted =
                  await PermissionService.checkNotificationPermission();
              if (granted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingCompleteScreen(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPermissionScreen(),
                  ),
                );
              }
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to save user data. Please try again.'),
                  backgroundColor: Colors.red,
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
          content: const Text('You have not verified your email yet.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Close'),
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
