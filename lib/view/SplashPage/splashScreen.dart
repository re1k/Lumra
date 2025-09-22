import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase import

class SplashGifScreen extends StatefulWidget {
  final Widget nextScreen; // This one is screen to go after initialization{LAYAN}
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
      await Future.delayed(const Duration(seconds: 8));

      // Once done, navigate to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen), ///this is the variable assigned earlier ^ 
      );
    // ignore: empty_catches
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/LumraSplash.GIF',
          height: 200,
          width: 200,
        ),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255), //the backgorund in here NOT white, bc the gif is not white as well
    );
  }
}
