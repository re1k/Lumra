import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/registration_controller.dart';
import 'package:lumra_project/controller/Registration/registration_flow_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/widgets/password_strength_indicator.dart';
import 'package:lumra_project/view/adhd_registration/verification_waiting_screen.dart';
import 'package:intl/intl.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late RegistrationController _controller;
  final RegistrationFlowController _flowController =
      Get.find<RegistrationFlowController>();

  @override
  void initState() {
    super.initState();
    _controller = RegistrationController();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _controller.dob ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1955, 1, 1), // January 1, 1955
      lastDate: DateTime(2019, 12, 31), // December 31, 2019
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
    if (picked != null && picked != _controller.dob) {
      _controller.setDateOfBirth(picked);
    }
    _controller.onDobFieldTouched();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _controller,
      child: Consumer<RegistrationController>(
        builder: (context, controller, child) {
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
                      SegmentedProgressBar(
                        currentStep: 7,
                        totalSteps: 7,
                      ), // Registration screen progress
                      const SizedBox(height: 32),
                      Text(
                        'Create your account',
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
                          boxShadow: [
                            BoxShadow(
                              color: BColors.darkGrey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: controller.emailController,
                          focusNode: controller.emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: controller.updateEmail,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            hintText: 'example@email.com',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: controller.emailFieldTouched
                                ? controller.emailError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.emailFieldTouched &&
                                        controller.emailError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.emailFieldTouched &&
                                        controller.emailError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.emailFieldTouched &&
                                        controller.emailError != null
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
                          boxShadow: [
                            BoxShadow(
                              color: BColors.darkGrey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: controller.passwordController,
                          focusNode: controller.passwordFocusNode,
                          obscureText: controller.obscurePassword,
                          onChanged: (value) {
                            controller.onPasswordChanged(value);
                            controller.updatePassword(value);
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
                            errorText: controller.passwordFieldTouched
                                ? controller.passwordError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.passwordFieldTouched &&
                                        controller.passwordError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.passwordFieldTouched &&
                                        controller.passwordError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.passwordFieldTouched &&
                                        controller.passwordError != null
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
                                controller.obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: BColors.darkGrey,
                              ),
                              onPressed: controller.togglePasswordVisibility,
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
                      if (controller.showPasswordStrength) ...[
                        PasswordStrengthIndicator(
                          password: controller.passwordController.text,
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
                          boxShadow: [
                            BoxShadow(
                              color: BColors.darkGrey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: controller.confirmPasswordController,
                          focusNode: controller.confirmPasswordFocusNode,
                          obscureText: controller.obscureConfirmPassword,
                          onChanged: controller.onConfirmPasswordChanged,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            hintText: 'Confirm your password',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: controller.confirmPasswordFieldTouched
                                ? controller.confirmPasswordError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.confirmPasswordFieldTouched &&
                                        controller.confirmPasswordError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.confirmPasswordFieldTouched &&
                                        controller.confirmPasswordError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.confirmPasswordFieldTouched &&
                                        controller.confirmPasswordError != null
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
                                controller.obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: BColors.darkGrey,
                              ),
                              onPressed:
                                  controller.toggleConfirmPasswordVisibility,
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
                                controller.setGender('Male');
                                controller.onGenderFieldTouched();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: controller.gender == 'Male'
                                      ? BColors.primary.withValues(alpha: 0.2)
                                      : Colors.white,
                                  border: Border.all(
                                    color:
                                        controller.genderFieldTouched &&
                                            controller.genderError != null
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
                                                  controller.gender == 'Male'
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
                                controller.setGender('Female');
                                controller.onGenderFieldTouched();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: controller.gender == 'Female'
                                      ? BColors.primary.withValues(alpha: 0.3)
                                      : Colors.white,
                                  border: Border.all(
                                    color:
                                        controller.genderFieldTouched &&
                                            controller.genderError != null
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
                                                  controller.gender == 'Female'
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
                      // Gender Error Message
                      if (controller.genderFieldTouched &&
                          controller.genderError != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            controller.genderError!,
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
                          borderRadius: BorderRadius.circular(8),
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
                            errorText: controller.dobFieldTouched
                                ? controller.dobError
                                : null,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.dobFieldTouched &&
                                        controller.dobError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.dobFieldTouched &&
                                        controller.dobError != null
                                    ? BColors.error
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    controller.dobFieldTouched &&
                                        controller.dobError != null
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
                            text: controller.dob != null
                                ? DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(controller.dob!)
                                : '',
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Create Account Button
                      Obx(
                        () => AppButton(
                          text: 'Create Account',
                          enabled: controller.validateForm(),
                          isLoading: _flowController.isLoading,
                          onPressed: () async {
                            if (controller.validateForm()) {
                              // Validate email format (local)
                              await controller.validateEmailWithFirebase(
                                controller.emailController.text,
                              );

                              // Check if email validation passed
                              if (controller.emailError == null) {
                                // Save registration data to GetX Controller
                                _flowController.updateFromRegistrationScreen(
                                  email: controller.emailController.text,
                                  password: controller.passwordController.text,
                                  gender: controller.selectedGender!,
                                  dob: controller.dateOfBirth!,
                                );

                                controller.saveRegistrationData();

                                // Create account
                                try {
                                  final success = await _flowController
                                      .createAccount();
                                  if (success) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const VerificationWaitingScreen(),
                                      ),
                                    );
                                  }
                                } on Exception catch (e) {
                                  // Handle exceptions
                                  if (e.toString().contains(
                                    'email-already-in-use',
                                  )) {
                                    setState(() {
                                      controller.emailError =
                                          'The email address is already in use';
                                    });
                                  } else {
                                    setState(() {
                                      controller.emailError =
                                          'An error occurred';
                                    });
                                  }
                                }
                              }
                              // If email validation failed, stay on the same screen
                              // The error will be shown in the UI
                            }
                          },
                        ),
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
    _controller.dispose();
    super.dispose();
  }
}
