import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/registration_controller.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/controller/Registration/name_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/widgets/password_strength_indicator.dart';
import 'package:lumra_project/view/caregiver_registration/child_account_check_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _registrationController = RegistrationController();
    _caregiverController = CaregiverController();
    _nameController = NameController();
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => _registrationController),
        ChangeNotifierProvider(create: (context) => _caregiverController),
      ],
      child: Consumer2<RegistrationController, CaregiverController>(
        builder: (context, regController, caregiverController, child) {
          return Scaffold(
            backgroundColor: BColors.white,
            appBar: AppBar(
              backgroundColor: BColors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Bar
                      SegmentedProgressBar(currentStep: 1, totalSteps: 4),
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
                        'Fill in your details to get started',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: BColors.black,
                          fontFamily: 'K2D',
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Name Field
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Name',
                              style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: BColors.black,
                                    fontFamily: 'K2D',
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: BColors.darkGrey,
                                  ),
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
                      // Name Field Container with Character Counter
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: BColors.darkGrey.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _nameController.nameController,
                              focusNode: _nameController.nameFocusNode,
                              maxLength: 16,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z ]'),
                                ),
                              ],
                              onChanged: _nameController.updateName,
                              onTapOutside: (event) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                hintText: 'Enter your name',
                                hintStyle: TextStyle(color: BColors.darkGrey),
                                counterText: '', // Hide the default counter
                                errorText: _nameController.nameFieldTouched
                                    ? _nameController.nameError
                                    : null,
                                errorStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color:
                                        _nameController.nameFieldTouched &&
                                            _nameController.nameError != null
                                        ? BColors.error
                                        : Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color:
                                        _nameController.nameFieldTouched &&
                                            _nameController.nameError != null
                                        ? BColors.error
                                        : Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color:
                                        _nameController.nameFieldTouched &&
                                            _nameController.nameError != null
                                        ? BColors.error
                                        : Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: BColors.error,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: BColors.error,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: BColors.black,
                                fontFamily: 'K2D',
                              ),
                            ),
                          ),
                          // Character Counter positioned at top-right
                          Positioned(
                            top: 8,
                            right: 12,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _nameController.characterCount,
                              builder: (context, count, child) {
                                return Text(
                                  '$count/16',
                                  style:
                                      const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: BColors.darkGrey,
                                        fontFamily: 'K2D',
                                      ).copyWith(
                                        fontSize: 12,
                                        color: BColors.darkGrey,
                                      ),
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
                              style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: BColors.black,
                                    fontFamily: 'K2D',
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: BColors.darkGrey,
                                  ),
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
                                    color: BColors.darkGrey.withValues(
                                      alpha: 0.1,
                                    ),
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
                          onChanged: regController.updateEmail,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            hintText: 'example@email.com',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: regController.emailFieldTouched
                                ? regController.emailError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.emailFieldTouched &&
                                        regController.emailError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.emailFieldTouched &&
                                        regController.emailError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.emailFieldTouched &&
                                        regController.emailError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: BColors.black,
                            fontFamily: 'K2D',
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
                              style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: BColors.black,
                                    fontFamily: 'K2D',
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: BColors.darkGrey,
                                  ),
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
                                    color: BColors.darkGrey.withValues(
                                      alpha: 0.1,
                                    ),
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
                          onChanged: (value) {
                            regController.onPasswordChanged(value);
                            regController.updatePassword(value);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: regController.passwordFieldTouched
                                ? regController.passwordError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.passwordFieldTouched &&
                                        regController.passwordError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.passwordFieldTouched &&
                                        regController.passwordError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.passwordFieldTouched &&
                                        regController.passwordError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                regController.obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: BColors.darkGrey,
                              ),
                              onPressed: regController.togglePasswordVisibility,
                            ),
                          ),
                          style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: BColors.black,
                                fontFamily: 'K2D',
                              ).copyWith(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.04,
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
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.03,
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
                              style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: BColors.black,
                                    fontFamily: 'K2D',
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: BColors.darkGrey,
                                  ),
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
                                    color: BColors.darkGrey.withValues(
                                      alpha: 0.1,
                                    ),
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
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            hintText: 'Confirm your password',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: regController.confirmPasswordFieldTouched
                                ? regController.confirmPasswordError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.confirmPasswordFieldTouched &&
                                        regController.confirmPasswordError !=
                                            null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.confirmPasswordFieldTouched &&
                                        regController.confirmPasswordError !=
                                            null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.confirmPasswordFieldTouched &&
                                        regController.confirmPasswordError !=
                                            null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                regController.obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: BColors.darkGrey,
                              ),
                              onPressed:
                                  regController.toggleConfirmPasswordVisibility,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: BColors.black,
                            fontFamily: 'K2D',
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
                              style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: BColors.black,
                                    fontFamily: 'K2D',
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: BColors.darkGrey,
                                  ),
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
                                regController.setGender('Male');
                                regController.onGenderFieldTouched();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: regController.gender == 'Male'
                                      ? BColors.primary.withValues(alpha: 0.2)
                                      : Colors.white,
                                  border: Border.all(
                                    color:
                                        regController.genderFieldTouched &&
                                            regController.genderError != null
                                        ? BColors.error
                                        : Colors.grey,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BColors.darkGrey.withValues(
                                        alpha: 0.1,
                                      ),
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
                                              color: BColors.darkGrey,
                                              fontWeight:
                                                  regController.gender == 'Male'
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
                                regController.setGender('Female');
                                regController.onGenderFieldTouched();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: regController.gender == 'Female'
                                      ? BColors.primary.withValues(alpha: 0.3)
                                      : Colors.white,
                                  border: Border.all(
                                    color:
                                        regController.genderFieldTouched &&
                                            regController.genderError != null
                                        ? BColors.error
                                        : Colors.grey,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BColors.darkGrey.withValues(
                                        alpha: 0.1,
                                      ),
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
                                              color: BColors.darkGrey,
                                              fontWeight:
                                                  regController.gender ==
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
                      if (regController.genderFieldTouched &&
                          regController.genderError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          regController.genderError!,
                          style:
                              const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: BColors.darkGrey,
                                fontFamily: 'K2D',
                              ).copyWith(
                                color: Colors.red,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.03,
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
                              style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: BColors.black,
                                    fontFamily: 'K2D',
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: BColors.darkGrey,
                                  ),
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
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: BColors.darkGrey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          readOnly: true,
                          onTap: _selectDateOfBirth,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            hintText: 'Select Date of Birth',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: regController.dobFieldTouched
                                ? regController.dobError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.dobFieldTouched &&
                                        regController.dobError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.dobFieldTouched &&
                                        regController.dobError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    regController.dobFieldTouched &&
                                        regController.dobError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: BColors.error,
                                width: 2,
                              ),
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: BColors.darkGrey,
                              size: 20,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: BColors.black,
                            fontFamily: 'K2D',
                          ),
                          controller: TextEditingController(
                            text: regController.dob != null
                                ? DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(regController.dob!)
                                : '',
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Create Account Button
                      AppButton(
                        enabled:
                            _nameController.isNextButtonEnabled &&
                            regController.validateForm(),
                        text: 'Next',
                        onPressed: () async {
                          if (_nameController.isNextButtonEnabled &&
                              regController.validateForm()) {
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

                              // Navigate to camera scan screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChildAccountCheckScreen(),
                                ),
                              );
                            } else {
                              // Email validation failed, show error message
                              regController.emailError = result['error'];
                              setState(() {});
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
        },
      ),
    );
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
// fix conflict!!!!!