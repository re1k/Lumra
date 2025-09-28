import 'package:flutter/material.dart';
import 'package:lumra_project/model/user_model.dart';

class RegistrationController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  final FocusNode genderFocusNode = FocusNode();
  final FocusNode dobFocusNode = FocusNode();

  UserModel _user = UserModel();
  String? selectedGender;
  DateTime? dateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showPasswordStrength = false;
  String? _passwordMismatchError;
  String? _emailError;
  bool _emailFieldTouched = false;
  String? _passwordError;
  bool _passwordFieldTouched = false;
  String? _genderError;
  bool _genderFieldTouched = false;
  String? _dobError;
  bool _dobFieldTouched = false;
  String? _confirmPasswordError;
  bool _confirmPasswordFieldTouched = false;

  UserModel get user => _user;
  String? get gender => selectedGender;
  DateTime? get dob => dateOfBirth;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get showPasswordStrength => _showPasswordStrength;
  String? get passwordMismatchError => _passwordMismatchError;
  String? get emailError => _emailError;

  // Setter for email error (for external access)
  set emailError(String? value) {
    _emailError = value;
    // Mark the field as touched so errorText appears immediately under the field
    if (value != null) {
      _emailFieldTouched = true;
    }
    notifyListeners();
  }

  bool get emailFieldTouched => _emailFieldTouched;
  String? get passwordError => _passwordError;
  bool get passwordFieldTouched => _passwordFieldTouched;
  String? get genderError => _genderError;
  bool get genderFieldTouched => _genderFieldTouched;
  String? get dobError => _dobError;
  bool get dobFieldTouched => _dobFieldTouched;
  String? get confirmPasswordError => _confirmPasswordError;
  bool get confirmPasswordFieldTouched => _confirmPasswordFieldTouched;

  void setGender(String gender) {
    selectedGender = gender;
    _user = _user.copyWith(gender: gender);
    // No validation for gender field
    notifyListeners();
  }

  void setDateOfBirth(DateTime dob) {
    dateOfBirth = dob;
    _user = _user.copyWith(dob: dob);
    if (_dobFieldTouched) {
      _validateDob();
    }
    // Real-time validation when field has been touched and has an error
    if (_dobFieldTouched && _dobError != null) {
      _validateDob();
    }
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    _showPasswordStrength = value.isNotEmpty;
    _checkPasswordMatch();

    // Real-time validation only when field has been touched and has an error
    if (_passwordFieldTouched && _passwordError != null) {
      _validatePassword(value);
    }

    // Update confirm password error only if confirm password field has been touched and has an error
    if (_confirmPasswordFieldTouched && _confirmPasswordError != null) {
      if (value == confirmPasswordController.text) {
        _confirmPasswordError = null;
      } else {
        _confirmPasswordError = "Passwords don't match";
      }
    }
    notifyListeners();
  }

  void onConfirmPasswordChanged(String value) {
    _checkPasswordMatch();
    // Mark field as touched when user starts typing
    if (value.isNotEmpty) {
      _confirmPasswordFieldTouched = true;
    }

    // Real-time validation only when field has been touched and has an error
    if (_confirmPasswordFieldTouched && _confirmPasswordError != null) {
      _validateConfirmPassword();
    }

    // Do not show error while typing - only validate on blur
    notifyListeners();
  }

  void onConfirmPasswordFieldTouched() {
    _confirmPasswordFieldTouched = true;
    notifyListeners();
  }

  void _validateConfirmPassword() {
    if (confirmPasswordController.text != passwordController.text) {
      _confirmPasswordError = "Passwords don't match";
    } else {
      _confirmPasswordError = null;
    }
  }

  void _checkPasswordMatch() {
    if (confirmPasswordController.text.isNotEmpty &&
        passwordController.text != confirmPasswordController.text) {
      _passwordMismatchError = 'Passwords do not match';
    } else {
      _passwordMismatchError = null;
    }
  }

  void updateEmail(String email) {
    // Apply unified email processing: trim and convert to lowercase
    final processedEmail = email.trim().toLowerCase();
    _user = _user.copyWith(email: processedEmail);

    // Real-time validation only when field has been touched and has an error
    // Only clear the error if the input becomes valid, don't show new errors
    if (_emailFieldTouched && _emailError != null) {
      _clearEmailErrorIfValid(email);
    }
    notifyListeners();
  }

  void onEmailFieldTouched() {
    _emailFieldTouched = true;
    notifyListeners();
  }

  void _validateEmail(String email) {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      _emailError = 'Email cannot be empty';
    } else if (_hasMiddleSpaces(trimmedEmail)) {
      _emailError = 'Email cannot contain spaces';
    } else if (!_isValidEmail(trimmedEmail)) {
      _emailError = 'The email address is not valid.';
    } else {
      _emailError = null;
    }
    // Force immediate update
    notifyListeners();
  }

  void _clearEmailErrorIfValid(String email) {
    final trimmedEmail = email.trim();

    // Special case: "Email cannot be empty" should disappear immediately when user starts typing
    if (_emailError == 'Email cannot be empty' && trimmedEmail.isNotEmpty) {
      _emailError = null;
    }
    // For other errors (spaces, invalid format), only clear if input becomes completely valid
    else if (trimmedEmail.isNotEmpty &&
        !_hasMiddleSpaces(trimmedEmail) &&
        _isValidEmail(trimmedEmail)) {
      _emailError = null;
    }
    // If input is still invalid, keep the existing error
  }

  /// Validate email and check if it's already in use
  Future<void> validateEmailWithFirebase(String email) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      _emailError = 'Email cannot be empty';
    } else if (_hasMiddleSpaces(trimmedEmail)) {
      _emailError = 'Email cannot contain spaces';
    } else if (!_isValidEmail(trimmedEmail)) {
      _emailError = 'The email address is not valid.';
    } else {
      // We'll check email availability during account creation
      // For now, just clear any existing errors
      _emailError = null;
    }
    notifyListeners();
  }

  String? validateEmailField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }

    final trimmedValue = value.trim();
    if (_hasMiddleSpaces(trimmedValue)) {
      return 'Email cannot contain spaces';
    } else if (!_isValidEmail(trimmedValue)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  bool _hasMiddleSpaces(String email) {
    // Check if the email (after trimming) contains any spaces
    return email.contains(' ');
  }

  bool _isValidEmail(String email) {
    // Check if email starts with a dot (invalid)
    if (email.startsWith('.')) {
      return false;
    }

    // Check basic email regex pattern
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    // Check if email domain is in allowed domains
    final allowedDomains = [
      "gmail.com",
      "outlook.com",
      "hotmail.com",
      "icloud.com",
      "yahoo.com",
    ];

    final domain = email.split('@').last;
    return allowedDomains.contains(domain.toLowerCase());
  }

  void updatePassword(String password) {
    _user = _user.copyWith(password: password);
    notifyListeners();
  }

  void onPasswordFieldTouched() {
    _passwordFieldTouched = true;
    notifyListeners();
  }

  void _validatePassword(String password) {
    // Check if password is empty and set error accordingly
    if (password.trim().isEmpty) {
      _passwordError = 'Password cannot be empty';
    } else {
      _passwordError = null;
    }
  }

  String? validatePasswordField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password cannot be empty';
    }
    return null;
  }

  bool _isValidPassword(String password) {
    // Check password strength requirements: 8+ chars, uppercase, number, symbol
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  void onGenderFieldTouched() {
    _genderFieldTouched = true;
    // No validation for gender field
    notifyListeners();
  }

  void onDobFieldTouched() {
    _dobFieldTouched = true;
    notifyListeners();
  }

  void _validateDob() {
    if (dateOfBirth == null) {
      _dobError = 'Please select your date of birth';
    } else {
      _dobError = null;
    }
  }

  bool validateForm() {
    final trimmedEmail = emailController.text.trim();
    return _isValidEmail(trimmedEmail) &&
        !_hasMiddleSpaces(trimmedEmail) &&
        _isValidPassword(passwordController.text) &&
        passwordController.text == confirmPasswordController.text &&
        selectedGender != null &&
        dateOfBirth != null;
  }

  void saveRegistrationData() {
    if (validateForm()) {
      _user = _user.copyWith(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
        gender: selectedGender,
        dob: dateOfBirth,
      );
    }
  }

  RegistrationController() {
    emailFocusNode.addListener(_onEmailFocusChanged);
    passwordFocusNode.addListener(_onPasswordFocusChanged);
    confirmPasswordFocusNode.addListener(_onConfirmPasswordFocusChanged);
    dobFocusNode.addListener(_onDobFocusChanged);
  }

  void _onEmailFocusChanged() {
    if (!emailFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate
      _emailFieldTouched = true;
      _validateEmail(emailController.text);
      notifyListeners();
    }
  }

  void _onPasswordFocusChanged() {
    if (!passwordFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate
      _passwordFieldTouched = true;
      _validatePassword(passwordController.text);
      notifyListeners();
    }
  }

  void _onConfirmPasswordFocusChanged() {
    if (!confirmPasswordFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate
      _confirmPasswordFieldTouched = true;
      _validateConfirmPassword();
      notifyListeners();
    }
  }

  void _onDobFocusChanged() {
    if (!dobFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate
      _dobFieldTouched = true;
      _validateDob();
      notifyListeners();
    }
  }

  /// Clear all registration data
  void clearAllData() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    selectedGender = null;
    dateOfBirth = null;
    _obscurePassword = true;
    _obscureConfirmPassword = true;
    _showPasswordStrength = false;
    _passwordMismatchError = null;
    _emailError = null;
    _emailFieldTouched = false;
    _passwordError = null;
    _passwordFieldTouched = false;
    _genderError = null;
    _genderFieldTouched = false;
    _dobError = null;
    _dobFieldTouched = false;
    _confirmPasswordError = null;
    _confirmPasswordFieldTouched = false;
    _user = UserModel();

    // Clear focus to prevent validation errors from showing
    emailFocusNode.unfocus();
    passwordFocusNode.unfocus();
    confirmPasswordFocusNode.unfocus();
    genderFocusNode.unfocus();
    dobFocusNode.unfocus();

    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailFocusNode.removeListener(_onEmailFocusChanged);
    emailFocusNode.dispose();
    passwordFocusNode.removeListener(_onPasswordFocusChanged);
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.removeListener(_onConfirmPasswordFocusChanged);
    confirmPasswordFocusNode.dispose();
    dobFocusNode.removeListener(_onDobFocusChanged);
    dobFocusNode.dispose();
    super.dispose();
  }
}
