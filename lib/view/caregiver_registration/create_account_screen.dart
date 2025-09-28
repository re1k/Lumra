import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/registration_controller.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/controller/Registration/name_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/widgets/password_strength_indicator.dart';
import 'package:lumra_project/view/caregiver_registration/permission_screen.dart';
import 'package:intl/intl.dart';

class CaregiverCreateAccountScreen extends StatefulWidget {
  const CaregiverCreateAccountScreen({super.key});

  @override
  State<CaregiverCreateAccountScreen> createState() =>
      _CaregiverCreateAccountScreenState();
}

class _CaregiverCreateAccountScreenState
    extends State<CaregiverCreateAccountScreen> {
  late RegistrationController _registrationController;
  late CaregiverController _caregiverController;
  late NameController _nameController;
  bool _isNextLoading = false;

  @override
  void initState() {
    super.initState();
    // Register controllers with GetX so they're available throughout the flow
    _registrationController = Get.put(RegistrationController());
    _caregiverController = Get.put(CaregiverController());
    _nameController = Get.put(NameController());

    // Reset caregiver controller for new registration session
    _caregiverController.resetForNewSession();

    // Add listeners to controllers for UI updates
    _registrationController.addListener(_onControllerChange);
    _nameController.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    setState(() {});
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _registrationController.dob ??
          DateTime(1980), // Default to middle of allowed range
      firstDate: DateTime(1955, 1, 1), // January 1, 1955
      lastDate: DateTime(2007, 12, 31), // December 31, 2007
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F8C85), // BColors.buttonPrimary
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _registrationController.dob) {
      _registrationController.setDateOfBirth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regController = _registrationController;
    return Scaffold(
      backgroundColor: BColors.white,
      appBar: AppBar(
        backgroundColor: BColors.white,
        leading: Padding(
          padding: const EdgeInsets.only(top: 17),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
            onPressed: () {
              // Clear all caregiver data when going back to WelcomePage
              _caregiverController.clearAllCaregiverData();
              _registrationController.clearAllData();
              _nameController.clearAllData();
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Bar
                SegmentedProgressBar(currentStep: 1, totalSteps: 3),
                const SizedBox(height: 32),
                Text(
                  'Create your caregiver account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Note that a caregiver account requires linking with an unlinked ADHD account',
                  style: const TextStyle(
                    fontSize: 18,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                ),
                const SizedBox(height: 20),
                // First Name Field
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'First Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' *',
                        style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // First Name Field Container with Character Counter
                Stack(
                  children: [
                    TextFormField(
                      controller: _nameController.firstNameController,
                      focusNode: _nameController.firstNameFocusNode,
                      maxLength: 16,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                      ],
                      onChanged: _nameController.updateFirstName,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Sarah',
                        hintStyle: TextStyle(color: BColors.darkGrey),
                        errorText: _nameController.firstNameFieldTouched
                            ? _nameController.firstNameError
                            : null,
                      ),
                    ),
                    // Character Counter positioned at top-right
                    Positioned(
                      top: 8,
                      right: 12,
                      child: ValueListenableBuilder<int>(
                        valueListenable:
                            _nameController.firstNameCharacterCount,
                        builder: (context, count, child) {
                          return Text(
                            '$count/16',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: BColors.darkGrey,
                              fontFamily: 'K2D',
                            ).copyWith(fontSize: 12, color: BColors.darkGrey),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Last Name Field
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Last Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' *',
                        style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Last Name Field Container with Character Counter
                Stack(
                  children: [
                    TextFormField(
                      controller: _nameController.lastNameController,
                      focusNode: _nameController.lastNameFocusNode,
                      maxLength: 16,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                      ],
                      onChanged: _nameController.updateLastName,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Aljohani',
                        hintStyle: TextStyle(color: BColors.darkGrey),
                        errorText: _nameController.lastNameFieldTouched
                            ? _nameController.lastNameError
                            : null,
                      ),
                    ),
                    // Character Counter positioned at top-right
                    Positioned(
                      top: 8,
                      right: 12,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _nameController.lastNameCharacterCount,
                        builder: (context, count, child) {
                          return Text(
                            '$count/16',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: BColors.darkGrey,
                              fontFamily: 'K2D',
                            ).copyWith(fontSize: 12, color: BColors.darkGrey),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Email Field
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Email address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' *',
                        style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow:
                        regController.emailFieldTouched &&
                            regController.emailError != null
                        ? [
                            BoxShadow(
                              color: BColors.darkGrey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormField(
                    controller: regController.emailController,
                    focusNode: regController.emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [LengthLimitingTextInputFormatter(128)],
                    onChanged: regController.updateEmail,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'example@gmail.com',
                      hintStyle: TextStyle(color: BColors.darkGrey),
                      errorText: regController.emailFieldTouched
                          ? regController.emailError
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Password Field
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Password',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' *',
                        style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow:
                        regController.passwordFieldTouched &&
                            regController.passwordError != null
                        ? [
                            BoxShadow(
                              color: BColors.darkGrey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormField(
                    controller: regController.passwordController,
                    focusNode: regController.passwordFocusNode,
                    obscureText: regController.obscurePassword,
                    inputFormatters: [LengthLimitingTextInputFormatter(128)],
                    onChanged: (value) {
                      regController.onPasswordChanged(value);
                      regController.updatePassword(value);
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: BColors.darkGrey),
                      errorText: regController.passwordFieldTouched
                          ? regController.passwordError
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          regController.obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: regController.togglePasswordVisibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Password Strength Indicator (only show after typing)
                if (regController.showPasswordStrength) ...[
                  PasswordStrengthIndicator(
                    password: regController.passwordController.text,
                  ),
                  const SizedBox(height: 12),
                ],
                // Password Rules
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'Password must include:\n• At least 8 characters\n• Include a number\n• Include a capital letter\n• Include a symbol',
                    style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: BColors.darkGrey,
                          fontFamily: 'K2D',
                        ).copyWith(
                          fontSize: MediaQuery.of(context).size.width * 0.03,
                          color: BColors.darkGrey,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm Password Field
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Confirm Password',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' *',
                        style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow:
                        regController.confirmPasswordFieldTouched &&
                            regController.confirmPasswordError != null
                        ? [
                            BoxShadow(
                              color: BColors.darkGrey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormField(
                    controller: regController.confirmPasswordController,
                    focusNode: regController.confirmPasswordFocusNode,
                    obscureText: regController.obscureConfirmPassword,
                    onChanged: regController.onConfirmPasswordChanged,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: BColors.darkGrey),
                      errorText: regController.confirmPasswordFieldTouched
                          ? regController.confirmPasswordError
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          regController.obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed:
                            regController.toggleConfirmPasswordVisibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Gender Selection
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Gender',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' *',
                        style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _registrationController.setGender('Male');
                          _registrationController.onGenderFieldTouched();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _registrationController.gender == 'Male'
                                ? BColors.primary.withValues(alpha: 0.2)
                                : Colors.white,
                            border: Border.all(
                              color:
                                  _registrationController.genderFieldTouched &&
                                      _registrationController.genderError !=
                                          null
                                  ? BColors.error
                                  : Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(14),
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
                              Expanded(
                                child: Text(
                                  'Male',
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: BColors.black,
                                        fontFamily: 'K2D',
                                      ).copyWith(
                                        fontWeight:
                                            _registrationController.gender ==
                                                'Male'
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _registrationController.setGender('Female');
                          _registrationController.onGenderFieldTouched();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _registrationController.gender == 'Female'
                                ? BColors.primary.withValues(alpha: 0.3)
                                : Colors.white,
                            border: Border.all(
                              color:
                                  _registrationController.genderFieldTouched &&
                                      _registrationController.genderError !=
                                          null
                                  ? BColors.error
                                  : Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(14),
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
                              Expanded(
                                child: Text(
                                  'Female',
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: BColors.black,
                                        fontFamily: 'K2D',
                                      ).copyWith(
                                        fontWeight:
                                            _registrationController.gender ==
                                                'Female'
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Gender error (if any)
                if (_registrationController.genderFieldTouched &&
                    _registrationController.genderError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _registrationController.genderError!,
                    style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: BColors.darkGrey,
                          fontFamily: 'K2D',
                        ).copyWith(
                          color: Colors.red,
                          fontSize: MediaQuery.of(context).size.width * 0.03,
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                // Date of Birth Field
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Date of Birth',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' *',
                        style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'YYYY/MM/DD',
                    hintStyle: TextStyle(color: BColors.darkGrey),
                    errorText: regController.dobFieldTouched
                        ? regController.dobError
                        : null,
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: regController.dob != null
                        ? DateFormat('yyyy-MM-dd').format(regController.dob!)
                        : '',
                  ),
                ),
                const SizedBox(height: 40),
                // Create Account Button
                AppButton(
                  enabled:
                      _nameController.isNextButtonEnabled &&
                      regController.validateForm(),
                  text: 'Next',
                  isLoading: _isNextLoading,
                  onPressed: () async {
                    if (_nameController.isNextButtonEnabled &&
                        regController.validateForm()) {
                      setState(() {
                        _isNextLoading = true;
                      });
                      // Call controller to validate email
                      final result = await _caregiverController
                          .validateEmailForRegistration(
                            regController.emailController.text,
                          );

                      if (result['success'] == true) {
                        // Email is valid and available, proceed to next step
                        // Save the data for later use
                        _nameController.saveName();
                        regController.saveRegistrationData();

                        // Store registration data in CaregiverController for persistence
                        _caregiverController.setRegistrationData(
                          email: regController.emailController.text.trim(),
                          password: regController.passwordController.text,
                          firstName: _nameController.firstNameController.text
                              .trim(),
                          lastName: _nameController.lastNameController.text
                              .trim(),
                          gender: regController.gender ?? '',
                          dob: regController.dob,
                        );

                        setState(() {
                          _isNextLoading = false;
                        });

                        // Navigate to permission screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CaregiverPermissionScreen(),
                          ),
                        );
                      } else {
                        // Email validation failed, show error message
                        setState(() {
                          _isNextLoading = false;
                          regController.emailError = result['error'];
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _registrationController.removeListener(_onControllerChange);
    _nameController.removeListener(_onControllerChange);
    // Don't manually dispose GetX-managed controllers
    // GetX will handle their lifecycle
    super.dispose();
  }
}
// fix conflict!!!!!