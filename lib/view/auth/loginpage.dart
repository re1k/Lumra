import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:get/get.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/auth/resetPassword.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? emailError;
  String? passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),

          SingleChildScrollView(
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
                      children: [
                        // ==== Email Field ====
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email),
                            labelText: 'Email Address',
                            errorText: emailError,
                          ),
                        ),

                        const SizedBox(height: BSizes.md),
                        // ==== Password Field ====
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            labelText: 'Password',
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

                        const SizedBox(height: BSizes.sm),

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
                                color: BColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: BSizes.xl + BSizes.md),
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
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: authController.isLoading.value
                                  ? null
                                  : () async {
                                      setState(() {
                                        emailError =
                                            emailController.text.isEmpty
                                            ? "Please enter your email"
                                            : null;
                                        passwordError =
                                            passwordController.text.isEmpty
                                            ? "Please enter your password"
                                            : null;
                                      });

                                      if (emailError == null &&
                                          passwordError == null) {
                                        final result = await authController
                                            .login(
                                              emailController.text.trim(),
                                              passwordController.text.trim(),
                                            );

                                        if (result != null) {
                                          setState(() {
                                            if (result ==
                                                "The email address is not valid.") {
                                              emailError = result;
                                              passwordError = null;
                                            } else {
                                              emailError = "";
                                              passwordError = result;
                                            }
                                          });
                                        }
                                      }
                                    },
                              child: authController.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
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
                              onTap: () {
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
        ],
      ),
    );
  }
}
