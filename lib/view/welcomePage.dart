import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/auth/loginPage.dart';
import 'package:lumra_project/view/navbar_widget.dart';

class Welcomepage extends StatelessWidget {
  const Welcomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),

          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF5F8C84).withOpacity(0.9),
                    const Color(0xFF8FA692),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE9B8A9).withOpacity(0.9),
                    const Color(0xFFFDE9C9),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              children: [
                const SizedBox(height: 200),
                Image.asset('assets/images/logo.png', height: 140),
                const SizedBox(height: 50),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ElevatedButton(
                    onPressed: () {
                      // Make the navbar the new root (removes Welcome )
                      //Get.offAll(() => const NavbarAdhd(selectedIndex: 0));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Register as ADHD person",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'K2D',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Register Caregiver
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ElevatedButton(
                    onPressed: () {
                      //Get.offAll(() => const NavbarCaregiver(selectedIndex: 0));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F8C84),

                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Register as Caregiver",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'K2D',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                          fontFamily: 'K2D',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),

                      TextButton(
                        // onPressed: () {
                        //   Get.to(LoginScreen());
                        // },
                        onPressed: () => Get.to(() => LoginScreen()),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontFamily: 'K2D',
                            fontWeight: FontWeight.w600,
                            color: BColors.primary,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
