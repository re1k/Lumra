import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Homepage/Mood/mood_tracking_controller.dart';

class MoodRow extends StatefulWidget {
  const MoodRow({super.key});

  @override
  State<MoodRow> createState() => _MoodRowState();
}

class _MoodRowState extends State<MoodRow> {
  late MoodTrackingController _moodController;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _moodSub;
  bool _isLocallyChosen = false;

  @override
  void initState() {
    super.initState();

    //  Remove old controller if it’s still in memory
    if (Get.isRegistered<MoodTrackingController>()) {
      print(" Deleting old MoodTrackingController...");
      Get.delete<MoodTrackingController>();
    }

    //  Create a brand-new one for this user
    _moodController = Get.put(MoodTrackingController());

    _moodController.startPeriodicCheck();

    //  Run a check immediately on app open
    _moodController.checkAndResetIfNeeded();

    //  Schedule automatic check at midnight
    _scheduleMidnightReset();

    _moodSub = _moodController.userMoodStream().listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};

      // if these fields change, re-run the reset logic
      final lastAdded = data['weeklyMood']?['lastAdded'];
      final dailyMood = data['dailyMood'];

      if (lastAdded != null || dailyMood != null) {
        _moodController.checkAndResetIfNeeded();
      }

      if (mounted) {
        setState(() {
          if (data['MoodChosenToday'] == false) {
            selectedMood = null;
          }
        });
      }
    });

    print(" New MoodTrackingController created in initState");
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);

    // Schedule the reset exactly at midnight
    Timer(diff, () async {
      print(" Midnight reached — resetting mood");
      await _moodController.checkAndResetIfNeeded();
      _scheduleMidnightReset(); // reschedule for the next midnight
    });
  }

  int? selectedMood;
  String? message;
  bool showMessage = false;

  //  Mood messages for each emoji
  final List<String> moodMessages = [
    "Oh no! Rough day, huh? ",
    "Hope things get better soon! ",
    "Neutral day — balance is good ",
    "Nice! Glad you’re feeling okay ",
    "Awesome! Keep that smile going ",
  ];

  void _onMoodSelected(int mood) async {
    if (_isLocallyChosen) return; // prevent double-clicks during transition

    setState(() {
      selectedMood = mood;
      message = moodMessages[mood];
      showMessage = true;
      _isLocallyChosen = true; // temporarily lock to avoid flicker
    });

    try {
      await _moodController.setTodayMood(mood + 1);
    } finally {
      // After Firestore confirms, ensure UI stays stable
      _isLocallyChosen = false;
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1500));
        setState(() {
          showMessage = false; // hide the text again after fade
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 48.0 : 56.0;

    const uid = 'mood-row';

    //  Listen to Firestore changes live
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      key: ValueKey(uid),
      stream: _moodController.userMoodStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() ?? {};
        final int dailyMood = data['dailyMood'] ?? 3;
        final bool chosen = data['MoodChosenToday'] ?? false;

        // Convert Firestore mood (1–5) → index (0–4)
        //  Prevent temporary flicker by keeping the local selection if just clicked
        if (!_isLocallyChosen) {
          selectedMood = chosen ? dailyMood - 1 : null;
        }

        if (chosen && _isLocallyChosen) {
          _isLocallyChosen = false;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 2.0, bottom: 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MoodIcon(
                    icon: Icons.sentiment_very_dissatisfied,
                    color: const Color(0xFFE57373),
                    isSelected: selectedMood == 0,
                    onTap: () => _onMoodSelected(0),
                    size: iconSize,
                  ),
                  _MoodIcon(
                    icon: Icons.sentiment_dissatisfied,
                    color: const Color(0xFFFFB74D),
                    isSelected: selectedMood == 1,
                    onTap: () => _onMoodSelected(1),
                    size: iconSize,
                  ),
                  _MoodIcon(
                    icon: Icons.sentiment_neutral,
                    color: const Color(0xFFFFF59D),
                    isSelected: selectedMood == 2,
                    onTap: () => _onMoodSelected(2),
                    size: iconSize,
                  ),
                  _MoodIcon(
                    icon: Icons.sentiment_satisfied,
                    color: const Color(0xFF81C784),
                    isSelected: selectedMood == 3,
                    onTap: () => _onMoodSelected(3),
                    size: iconSize,
                  ),
                  _MoodIcon(
                    icon: Icons.sentiment_very_satisfied,
                    color: const Color(0xFF4CAF50),
                    isSelected: selectedMood == 4,
                    onTap: () => _onMoodSelected(4),
                    size: iconSize,
                  ),
                ],
              ),
            ),

            //  Fading message below emojis
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1000),
              opacity: showMessage ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    message ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3C3C3C),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------

class _MoodIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const _MoodIcon({
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? size * 1.2 : size,
        height: isSelected ? size * 1.2 : size,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : BColors.white,
          borderRadius: BorderRadius.circular(
            isSelected ? (size * 1.2) / 2 : size / 2,
          ),
          border: Border.all(
            color: isSelected ? color : BColors.grey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
