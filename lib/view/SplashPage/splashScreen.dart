import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lumra_project/theme/base_themes/colors.dart'; // Firebase import

class SplashGifScreen extends StatefulWidget {
  final Widget
  nextScreen; // This one is screen to go after initialization{LAYAN}
  const SplashGifScreen({super.key, required this.nextScreen});

  @override
  State<SplashGifScreen> createState() => _SplashGifScreenState();
}

class _SplashGifScreenState extends State<SplashGifScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp(); // Functions To Start Firebase, so that when loading is done its done also
  }

  // Initialize Firebase
  Future<void> _initializeApp() async {
    try {
      // Wait for Firebase to initialize
      await Firebase.initializeApp();

      //extra delay bc i want the GIF to be visible longer
      await Future.delayed(const Duration(seconds: 7));

      // Once done, navigate to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen),

        ///this is the variable assigned earlier ^
      );
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(252, 255, 255, 255),
      body: Stack(
        children: [
          // Centered GIF
          Center(
            child: Image.asset(
              'assets/images/LumraSplash.GIF',
              height: 200,
              width: 200,
            ),
          ),
          // Skip button at top left
          Positioned(
            top: 72, // adjust depending on status bar height
            left: 24,
            child: GestureDetector(
              onTap: () {
                // Navigate to next screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => widget.nextScreen),
                );
              },
              child: Text(
                'Skip',
                style: const TextStyle(
                  decoration: TextDecoration.underline, // adds underline
                  decorationColor: BColors.darkGrey, // underline color
                  decorationThickness: 2,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BColors.darkGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
