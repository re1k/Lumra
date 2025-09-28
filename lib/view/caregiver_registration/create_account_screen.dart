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
    _registrationController = Get.put(RegistrationController());
    _caregiverController = Get.put(CaregiverController());
    _nameController = Get.put(NameController());

    _caregiverController.resetForNewSession();

    _registrationController.addListener(_onControllerChange);
    _nameController.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  void _navigateSafely(Function action) {
    FocusScope.of(context).unfocus();
    action();
  }

  void _navigateSafelyAsync(Future<void> Function() action) {
    FocusScope.of(context).unfocus();
    action();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _registrationController.dob ?? DateTime(1980),
      firstDate: DateTime(1955, 1, 1),
      lastDate: DateTime(2007, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F8C85),
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: BColors.white,
        leading: Padding(
          padding: const EdgeInsets.only(top: 17),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
            onPressed: () {
              _navigateSafely(() {
                _caregiverController.clearAllCaregiverData();
                _registrationController.clearAllData();
                _nameController.clearAllData();
                Navigator.pop(context);
              });
            },
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedProgressBar(currentStep: 1, totalSteps: 3),
                const SizedBox(height: 32),

                const Text(
                  'Create your caregiver account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Note that a caregiver account requires linking with an unlinked ADHD account',
                  style: TextStyle(
                    fontSize: 18,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                ),
                const SizedBox(height: 20),

                // First Name
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'First Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'K2D',
                        ).copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Stack(
                  children: [
                    TextFormField(
                      controller: _nameController.firstNameController,
                      focusNode: _nameController.firstNameFocusNode,
                      maxLength: 12,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                      ],
                      onChanged: _nameController.updateFirstName,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Sarah',
                        hintStyle: const TextStyle(color: BColors.darkGrey),
                        errorText: _nameController.firstNameFieldTouched
                            ? _nameController.firstNameError
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 12,
                      child: ValueListenableBuilder<int>(
                        valueListenable:
                            _nameController.firstNameCharacterCount,
                        builder: (context, count, child) {
                          return Text(
                            '$count/12',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BColors.darkGrey,
                              fontFamily: 'K2D',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Last Name
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Last Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'K2D',
                        ).copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Stack(
                  children: [
                    TextFormField(
                      controller: _nameController.lastNameController,
                      focusNode: _nameController.lastNameFocusNode,
                      maxLength: 12,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                      ],
                      onChanged: _nameController.updateLastName,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Aljohani',
                        hintStyle: const TextStyle(color: BColors.darkGrey),
                        errorText: _nameController.lastNameFieldTouched
                            ? _nameController.lastNameError
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 12,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _nameController.lastNameCharacterCount,
                        builder: (context, count, child) {
                          return Text(
                            '$count/12',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BColors.darkGrey,
                              fontFamily: 'K2D',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Email
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Email address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'K2D',
                        ).copyWith(color: Colors.red),
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
                              color: BColors.darkGrey.withOpacity(0.1),
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
                      hintStyle: const TextStyle(color: BColors.darkGrey),
                      errorText: regController.emailFieldTouched
                          ? regController.emailError
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Password
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'K2D',
                        ).copyWith(color: Colors.red),
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
                              color: BColors.darkGrey.withOpacity(0.1),
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
                      hintStyle: const TextStyle(color: BColors.darkGrey),
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

                if (regController.showPasswordStrength) ...[
                  PasswordStrengthIndicator(
                    password: regController.passwordController.text,
                  ),
                  const SizedBox(height: 12),
                ],

                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'Password must include:\n• At least 8 characters\n• Include a number\n• Include a capital letter\n• Include a symbol',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      color: BColors.darkGrey,
                      fontFamily: 'K2D',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm Password
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Confirm Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'K2D',
                        ).copyWith(color: Colors.red),
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
                              color: BColors.darkGrey.withOpacity(0.1),
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
                      hintStyle: const TextStyle(color: BColors.darkGrey),
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

                // Gender
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Gender',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'K2D',
                        ).copyWith(color: Colors.red),
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
                                ? BColors.primary.withOpacity(0.2)
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
                                color: BColors.darkGrey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(child: Text('Male')),
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
                                ? BColors.primary.withOpacity(0.3)
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
                                color: BColors.darkGrey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(child: Text('Female')),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_registrationController.genderFieldTouched &&
                    _registrationController.genderError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _registrationController.genderError!,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      color: Colors.red,
                      fontFamily: 'K2D',
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Date of Birth
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Date of Birth',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'K2D',
                        ).copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                  controller: TextEditingController(
                    text: regController.dob != null
                        ? DateFormat('yyyy-MM-dd').format(regController.dob!)
                        : '',
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'YYYY/MM/DD',
                    hintStyle: const TextStyle(color: BColors.darkGrey),
                    errorText: regController.dobFieldTouched
                        ? regController.dobError
                        : null,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 40),

                // Next Button
                AppButton(
                  enabled:
                      _nameController.isNextButtonEnabled &&
                      regController.validateForm(),
                  text: 'Next',
                  isLoading: _isNextLoading,
                  onPressed: () {
                    _navigateSafelyAsync(() async {
                      if (_nameController.isNextButtonEnabled &&
                          regController.validateForm()) {
                        setState(() {
                          _isNextLoading = true;
                        });

                        final result = await _caregiverController
                            .validateEmailForRegistration(
                              regController.emailController.text,
                            );

                        if (result['success'] == true) {
                          _nameController.saveName();
                          regController.saveRegistrationData();

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

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CaregiverPermissionScreen(),
                            ),
                          );
                        } else {
                          setState(() {
                            _isNextLoading = false;
                            regController.emailError = result['error'];
                          });
                        }
                      }
                    });
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
    _registrationController.removeListener(_onControllerChange);
    _nameController.removeListener(_onControllerChange);
    super.dispose();
  }
}
