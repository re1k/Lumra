import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:get/get.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/auth/resetPassword.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late TapGestureRecognizer _tapRecognizer;

  bool _obscurePassword = true;
  String? emailError;
  String? passwordError;

  int _resendCooldown = 0;
  Timer? _resendTimer;

  final allowedDomains = [
    "gmail.com",
    "outlook.com",
    "hotmail.com",
    "icloud.com",
    "yahoo.com",
  ];

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () async {
        final user = authController.currentUser;
        if (user != null && !user.emailVerified) {
          try {
            await user.sendEmailVerification();
            _startResendCooldown();
            setState(() {
              emailError = "EMAIL_NOT_VERIFIED";
            });
            _startResendCooldown();
          } catch (e) {
            if (e.toString().contains("too-many-requests")) {
              setState(() {
                emailError = "TOO_MANY_REQUESTS";
              });
            }
          }
        }
      };
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _tapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BSizes.lg,
              vertical: BSizes.xl + BSizes.md,
            ),

            child: Column(
              children: [
                const SizedBox(height: BSizes.xl + BSizes.md),
                Image.asset('assets/images/logo.png', height: 140),
                const SizedBox(height: BSizes.xl + BSizes.sm),

                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'K2D',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: BSizes.xl + BSizes.sm),

                Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==== Email Field ====
                      Text(
                        "Email Address",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(128),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.email),
                          errorText:
                              (emailError != null &&
                                  emailError != "EMAIL_NOT_VERIFIED" &&
                                  emailError != "TOO_MANY_REQUESTS")
                              ? emailError
                              : null,
                        ),
                      ),

                      const SizedBox(height: BSizes.md),

                      // ==== Password Field ====
                      Text(
                        "Password",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(128),
                        ],
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock),
                          errorText: passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      // ==== Forgot Password Button ====
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ResetPasswordDialog.show(context, authController);
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeSm,
                              color: BColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // ==== Email not verified message ====
                      if (emailError == "EMAIL_NOT_VERIFIED" ||
                          emailError == "TOO_MANY_REQUESTS")
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: emailError == "TOO_MANY_REQUESTS"
                                ? const Text(
                                    "Too many requests were made to verify your account, please try again after an hour",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: BColors.error,
                                      fontFamily: 'K2D',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : (_resendCooldown == 0)
                                ? (_resendTimer == null
                                      // First time
                                      ? RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontFamily: 'K2D',
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    "Your email is not verified \n reset your password or ",
                                                style: TextStyle(
                                                  fontSize: BSizes.md,
                                                  color: BColors.error,
                                                ),
                                              ),
                                              TextSpan(
                                                text: " Tap here to verify",
                                                style: const TextStyle(
                                                  color: BColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'K2D',
                                                  fontSize: BSizes.md,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer: _tapRecognizer,
                                              ),
                                            ],
                                          ),
                                        )
                                      // After timer finishes
                                      : TextButton(
                                          onPressed: () async {
                                            final user =
                                                authController.currentUser;
                                            if (user != null &&
                                                !user.emailVerified) {
                                              await user
                                                  .sendEmailVerification();
                                              _startResendCooldown();
                                              setState(() {
                                                emailError =
                                                    "EMAIL_NOT_VERIFIED";
                                              });
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            "Resend verification email",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: BColors.primary,
                                              fontFamily: 'K2D',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ))
                                // During cooldown
                                : Text(
                                    "Verification email sent. Resend in ${_resendCooldown}s",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: BColors.primary,
                                      fontFamily: 'K2D',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                      const SizedBox(height: 20),
                      // ==== Sign In Button ====
                      Obx(
                        () => SizedBox(
                          width: double.infinity,

                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BColors.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: BSizes.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: authController.isLoading.value
                                ? null
                                : () async {
                                    if (emailError != "EMAIL_NOT_VERIFIED") {
                                      setState(() {
                                        emailError = null;
                                        passwordError = null;
                                        _resendCooldown = 0;
                                        _resendTimer?.cancel();
                                        _resendTimer = null;
                                      });
                                    }

                                    final email = emailController.text
                                        .trim()
                                        .toLowerCase();
                                    final password = passwordController.text;

                                    setState(() {
                                      emailError = email.isEmpty
                                          ? "Please enter your email"
                                          : null;
                                      passwordError = password.isEmpty
                                          ? "Please enter your password"
                                          : null;
                                    });

                                    if (emailError == null &&
                                        passwordError == null) {
                                      final domain = email.split('@').last;

                                      if (!allowedDomains.contains(domain)) {
                                        setState(() {
                                          emailError =
                                              "The email address is not valid.";
                                          passwordError = null;
                                        });
                                        return;
                                      }

                                      final result = await authController.login(
                                        email,
                                        password,
                                      );

                                      if (result != null) {
                                        setState(() {
                                          if (result == "EMAIL_NOT_VERIFIED") {
                                            emailError = "EMAIL_NOT_VERIFIED";
                                            passwordError = null;
                                          } else if (result ==
                                              "The email address is not valid.") {
                                            emailError = result;
                                            passwordError = null;
                                          } else {
                                            emailError = null;
                                            passwordError = result;
                                          }
                                        });
                                      }
                                    }
                                  },
                            child: authController.isLoading.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'K2D',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: BSizes.md + BSizes.sm),
                      // ==== Register Text ====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don’t have an account? ",
                            style: TextStyle(
                              fontFamily: 'K2D',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              /*  FocusScope.of(context).unfocus();
                              await Future.delayed(
                                const Duration(milliseconds: 150),
                              ); */
                              Get.to(() => const Welcomepage());
                            },
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                fontFamily: 'K2D',
                                fontSize: 14,
                                color: BColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
