import 'package:flutter/material.dart';
import 'package:lumra_project/model/user_model.dart';

class NameController extends ChangeNotifier {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode lastNameFocusNode = FocusNode();
  final ValueNotifier<int> firstNameCharacterCount = ValueNotifier<int>(0);
  final ValueNotifier<int> lastNameCharacterCount = ValueNotifier<int>(0);
  UserModel _user = UserModel();

  String? _firstNameError;
  String? _lastNameError;
  bool _firstNameFieldTouched = false;
  bool _lastNameFieldTouched = false;

  UserModel get user => _user;
  String? get firstNameError => _firstNameError;
  String? get lastNameError => _lastNameError;
  bool get firstNameFieldTouched => _firstNameFieldTouched;
  bool get lastNameFieldTouched => _lastNameFieldTouched;

  // Legacy variables for backward compatibility
  String? _nameError;
  bool _nameFieldTouched = false;

  // Legacy getters for backward compatibility
  TextEditingController get nameController => firstNameController;
  FocusNode get nameFocusNode => firstNameFocusNode;
  ValueNotifier<int> get characterCount => firstNameCharacterCount;
  String? get nameError => _nameError;
  bool get nameFieldTouched => _nameFieldTouched;

  NameController() {
    // Listen to text changes and update character count
    firstNameController.addListener(_onFirstNameTextChanged);
    lastNameController.addListener(_onLastNameTextChanged);
    firstNameFocusNode.addListener(_onFirstNameFocusChanged);
    lastNameFocusNode.addListener(_onLastNameFocusChanged);
  }

  void _onFirstNameTextChanged() {
    final text = firstNameController.text;
    firstNameCharacterCount.value = text.length;

    // Real-time validation only when field has been touched and has an error
    if (_firstNameFieldTouched && _firstNameError != null) {
      _validateFirstNameField();
    }

    notifyListeners();
  }

  void _onLastNameTextChanged() {
    final text = lastNameController.text;
    lastNameCharacterCount.value = text.length;

    // Real-time validation only when field has been touched and has an error
    if (_lastNameFieldTouched && _lastNameError != null) {
      _validateLastNameField();
    }

    notifyListeners();
  }

  void updateFirstName(String firstName) {
    _user = _user.copyWith(firstName: firstName);
    notifyListeners();
  }

  void updateLastName(String lastName) {
    _user = _user.copyWith(lastName: lastName);
    notifyListeners();
  }

  // Legacy method for backward compatibility
  void updateName(String name) {
    _user = _user.copyWith(name: name);
    notifyListeners();
  }

  /// Validates the first name according to the specified rules:
  /// - Maximum of 16 characters
  /// - English letters and spaces only (A-Z, a-z, space)
  /// - No numbers, no special characters
  /// - Must not be empty
  bool validateFirstName() {
    final text = firstNameController.text.trim();

    // Check if empty
    if (text.isEmpty) return false;

    // Check minimum length (at least 2 characters)
    if (text.length < 2) return false;

    return true;
  }

  /// Validates the last name according to the specified rules:
  /// - Maximum of 16 characters
  /// - English letters and spaces only (A-Z, a-z, space)
  /// - No numbers, no special characters
  /// - Must not be empty
  bool validateLastName() {
    final text = lastNameController.text.trim();

    // Check if empty
    if (text.isEmpty) return false;

    // Check minimum length (at least 2 characters)
    if (text.length < 2) return false;

    return true;
  }

  /// Legacy validateName method for backward compatibility
  bool validateName() {
    final text = nameController.text.trim();

    // Check if empty
    if (text.isEmpty) return false;

    // Check minimum length (at least 2 characters)
    if (text.length < 2) return false;

    return true;
  }

  /// Returns true if the Next button should be enabled
  /// Requires at least 2 valid characters for both first and last name
  bool get isNextButtonEnabled {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    return firstName.length >= 2 &&
        lastName.length >= 2 &&
        validateFirstName() &&
        validateLastName();
  }

  void saveFirstName() {
    if (validateFirstName()) {
      updateFirstName(firstNameController.text.trim());
    }
  }

  void saveLastName() {
    if (validateLastName()) {
      updateLastName(lastNameController.text.trim());
    }
  }

  void saveName() {
    if (validateName()) {
      updateName(nameController.text.trim());
    }
  }

  void onFirstNameFieldTouched() {
    _firstNameFieldTouched = true;
    // Do not validate on touch - only validate on blur
    notifyListeners();
  }

  void onLastNameFieldTouched() {
    _lastNameFieldTouched = true;
    // Do not validate on touch - only validate on blur
    notifyListeners();
  }

  void onNameFieldTouched() {
    _nameFieldTouched = true;
    // Do not validate on touch - only validate on blur
    notifyListeners();
  }

  // Legacy method for backward compatibility
  void _onTextChanged() {
    final text = nameController.text;
    characterCount.value = text.length;

    // Real-time validation only when field has been touched and has an error
    if (_nameFieldTouched && _nameError != null) {
      _validateNameField();
    }

    notifyListeners();
  }

  void _validateFirstNameField() {
    final text = firstNameController.text.trim();

    if (text.isEmpty) {
      _firstNameError = 'First name cannot be empty';
    } else if (text.length < 2) {
      _firstNameError = 'First name must be at least 2 characters';
    } else {
      _firstNameError = null;
    }
    // Force immediate update
    notifyListeners();
  }

  void _validateLastNameField() {
    final text = lastNameController.text.trim();

    if (text.isEmpty) {
      _lastNameError = 'Last name cannot be empty';
    } else if (text.length < 2) {
      _lastNameError = 'Last name must be at least 2 characters';
    } else {
      _lastNameError = null;
    }
    // Force immediate update
    notifyListeners();
  }

  void _validateNameField() {
    final text = nameController.text.trim();

    if (text.isEmpty) {
      _nameError = 'Name cannot be empty';
    } else if (text.length < 2) {
      _nameError = 'Name must be at least 2 characters';
    } else {
      _nameError = null;
    }
    // Force immediate update
    notifyListeners();
  }

  void _onFirstNameFocusChanged() {
    if (!firstNameFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate immediately
      _firstNameFieldTouched = true;
      _validateFirstNameField();
    }
  }

  void _onLastNameFocusChanged() {
    if (!lastNameFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate immediately
      _lastNameFieldTouched = true;
      _validateLastNameField();
    }
  }

  void _onNameFocusChanged() {
    if (!nameFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate immediately
      _nameFieldTouched = true;
      _validateNameField();
    }
  }

  // Additional method to handle validation when field loses focus
  void onFirstNameFieldBlur() {
    _firstNameFieldTouched = true;
    _validateFirstNameField();
    notifyListeners();
  }

  void onLastNameFieldBlur() {
    _lastNameFieldTouched = true;
    _validateLastNameField();
    notifyListeners();
  }

  void onNameFieldBlur() {
    _nameFieldTouched = true;
    _validateNameField();
    notifyListeners();
  }

  /// Clear all name data
  void clearAllData() {
    firstNameController.clear();
    lastNameController.clear();
    _firstNameError = null;
    _lastNameError = null;
    _firstNameFieldTouched = false;
    _lastNameFieldTouched = false;
    _nameError = null;
    _nameFieldTouched = false;
    _user = UserModel();
    firstNameCharacterCount.value = 0;
    lastNameCharacterCount.value = 0;

    // Clear focus to prevent validation errors from showing
    firstNameFocusNode.unfocus();
    lastNameFocusNode.unfocus();

    notifyListeners();
  }

  @override
  void dispose() {
    firstNameController.removeListener(_onFirstNameTextChanged);
    firstNameController.dispose();
    lastNameController.removeListener(_onLastNameTextChanged);
    lastNameController.dispose();
    firstNameFocusNode.removeListener(_onFirstNameFocusChanged);
    firstNameFocusNode.dispose();
    lastNameFocusNode.removeListener(_onLastNameFocusChanged);
    lastNameFocusNode.dispose();
    firstNameCharacterCount.dispose();
    lastNameCharacterCount.dispose();
    // Legacy cleanup
    nameController.removeListener(_onTextChanged);
    nameController.dispose();
    nameFocusNode.removeListener(_onNameFocusChanged);
    nameFocusNode.dispose();
    characterCount.dispose();
    super.dispose();
  }
}
