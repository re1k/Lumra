import 'package:flutter/material.dart';
import 'package:lumra_project/model/user_model.dart';

class NameController extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();
  final ValueNotifier<int> characterCount = ValueNotifier<int>(0);
  UserModel _user = UserModel();

  String? _nameError;
  bool _nameFieldTouched = false;

  UserModel get user => _user;
  String? get nameError => _nameError;
  bool get nameFieldTouched => _nameFieldTouched;

  NameController() {
    // Listen to text changes and update character count
    nameController.addListener(_onTextChanged);
    nameFocusNode.addListener(_onNameFocusChanged);
  }

  void _onTextChanged() {
    final text = nameController.text;
    characterCount.value = text.length;

    // Real-time validation only when field has been touched and has an error
    if (_nameFieldTouched && _nameError != null) {
      _validateNameField();
    }

    notifyListeners();
  }

  void updateName(String name) {
    _user = _user.copyWith(name: name);
    notifyListeners();
  }

  /// Validates the name according to the specified rules:
  /// - Maximum of 16 characters
  /// - English letters and spaces only (A-Z, a-z, space)
  /// - No numbers, no special characters
  /// - Must not be empty
  bool validateName() {
    final text = nameController.text.trim();

    // Check if empty
    if (text.isEmpty) return false;

    // Check minimum length (at least 2 characters)
    if (text.length < 2) return false;

    return true;
  }

  /// Returns true if the Next button should be enabled
  /// Requires at least 2 valid characters
  bool get isNextButtonEnabled {
    final text = nameController.text.trim();
    return text.length >= 2 && validateName();
  }

  void saveName() {
    if (validateName()) {
      updateName(nameController.text.trim());
    }
  }

  void onNameFieldTouched() {
    _nameFieldTouched = true;
    // Do not validate on touch - only validate on blur
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

  void _onNameFocusChanged() {
    if (!nameFocusNode.hasFocus) {
      // Field lost focus - mark as touched and validate immediately
      _nameFieldTouched = true;
      _validateNameField();
    }
  }

  // Additional method to handle validation when field loses focus
  void onNameFieldBlur() {
    _nameFieldTouched = true;
    _validateNameField();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.removeListener(_onTextChanged);
    nameController.dispose();
    nameFocusNode.removeListener(_onNameFocusChanged);
    nameFocusNode.dispose();
    characterCount.dispose();
    super.dispose();
  }
}
