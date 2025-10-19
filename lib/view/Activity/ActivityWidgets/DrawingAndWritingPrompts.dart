import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:get/get.dart';

class ActivityPrompts extends StatelessWidget {
  final String activityTitle;
  final int minutes;
  const ActivityPrompts({
    super.key,
    required this.activityTitle,
    required this.minutes,
  });

  String getRandomPrompt() {
    final random = Random();
    //https://www.psychologytoday.com/us/blog/arts-and-health/201311/top-ten-art-therapy-visual-journaling-prompts
    //note this is art thearpy in general not ADHD
    final drawingList = [
      "Draw your current emotions using colors, shapes, lines, textures, or images — without worrying about literal representation.",
      "Make a “scribble” or free-form lines/doodles. Then look at them, see what images or shapes emerge, and develop them further in your drawing.",
      "Draw symbols and words that visualize a personal goal, wish, or intention for yourself.",
    ];

    //https://www.reflection.app/blog/the-ultimate-guide-to-journaling-for-adhd
    final writingList = [
      "Describe a recent situation where your emotions felt too intense. What triggered this response?",
      "Write a letter to your ADHD, acknowledging both its challenges and gifts.",
      "What are three things you genuinely appreciate about your ADHD brain?",
      "What does success look like for someone with your unique ADHD profile?",
    ];

    if (activityTitle.toLowerCase().contains('draw')) {
      return drawingList[random.nextInt(drawingList.length)];
    } else {
      return writingList[random.nextInt(writingList.length)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = getRandomPrompt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
          'assets/animation/PencilAnimation.json',
          height: BSizes.iconLg * 2,
        ),
        const SizedBox(height: 16),
        Text(
          'Prompt for You',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: BColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Get.to(null);
            },
            child: const Text(
              "Let's Start!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
