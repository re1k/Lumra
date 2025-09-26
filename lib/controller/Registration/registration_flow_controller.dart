import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumra_project/service/auth_signup.dart';

class RegistrationFlowController extends GetxController {
  // Collected data from all screens
  final RxString _name = ''.obs;
  final RxString _email = ''.obs;
  final RxString _password = ''.obs;
  final RxString _gender = ''.obs;
  final Rx<DateTime?> _dob = Rx<DateTime?>(null);
  final RxString _role = 'adhd'.obs;
  final RxInt _totalPoints = 0.obs;
  final RxList<int> _answers = <int>[].obs;
  final RxBool _isLoading = false.obs;
  // Points per question index to ensure idempotent calculation when answers change
  final RxMap<int, int> _questionPoints = <int, int>{}.obs;

  // Getters
  String get name => _name.value;
  String get email => _email.value;
  String get password => _password.value;
  String get gender => _gender.value;
  DateTime? get dob => _dob.value;
  String get role => _role.value;
  int get totalPoints => _totalPoints.value;
  bool get isLoading => _isLoading.value;

  // Update data from each screen
  void updateFromNameScreen(String name) {
    _name.value = name;
  }

  void updateFromQuestionsScreen(List<int> answers) {
    _answers.assignAll(answers);
    _totalPoints.value = answers.fold(0, (total, answer) => total + answer);
  }

  /// Add points to the running total (for progressive point calculation)
  void addPoints(int points) {
    _totalPoints.value += points;
  }

  /// Set points for a specific question index and recompute the total.
  /// This ensures that changing an answer replaces the old points instead of accumulating.
  void setQuestionPoints(int questionIndex, int points) {
    _questionPoints[questionIndex] = points;
    _totalPoints.value = _questionPoints.values.fold(
      0,
      (total, p) => total + p,
    );
  }

  void updateFromRegistrationScreen({
    required String email,
    required String password,
    required String gender,
    required DateTime dob,
  }) {
    _email.value = email;
    _password.value = password;
    _gender.value = gender;
    _dob.value = dob;
  }

  // Create final account
  Future<bool> createAccount() async {
    _isLoading.value = true;

    try {
      // Use Firebase Auth service
      final bool success = await FirebaseAuthService.createCompleteAccount(
        email: _email.value,
        password: _password.value,
        role: _role.value,
        name: _name.value,
        gender: _gender.value,
        dob: _dob.value,
        totalPoints: _totalPoints.value,
      );

      _isLoading.value = false;
      return success;
    } on Exception catch (e) {
      _isLoading.value = false;
      // Check if it's an email already in use error
      if (e.toString().contains('email-already-in-use')) {
        // Re-throw for UI to handle with specific error message
        throw Exception('email-already-in-use');
      }

      return false;
    } catch (e) {
      // Handle any other unexpected errors
      _isLoading.value = false;
      return false;
    }
  }

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      // Reload the current user to get the latest verification status
      await FirebaseAuth.instance.currentUser?.reload();

      // Check if email is verified
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
}
