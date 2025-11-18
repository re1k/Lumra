import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class DailyMoodNotification {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  StreamSubscription<DocumentSnapshot>? _moodSubscription;

  // Function to request notification permission
  Future<void> requestNotificationPermission() async {
    // Check if notification permission is denied
    if (await Permission.notification.isDenied) {
      // Request the permission
      await Permission.notification.request();
    }
  }

  /// Initialize notifications and timezone
  Future<void> init(String uid) async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

    const androidSettings = AndroidInitializationSettings('@mipmap/logo');
    const settings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
    await requestNotificationPermission();
    _initialized = true;

    //  real time dailyMood
    _moodSubscription?.cancel();
    _moodSubscription = _db.collection('users').doc(uid).snapshots().listen((
      doc,
    ) async {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final dailyMood = data['dailyMood'] ?? 3;
        //    if rhe mood updated
        await scheduleDailyNotification(dailyMood: dailyMood);
      }
    });
  }

  /// Schedule daily notification based on user's dailyMode from Firestore
  Future<void> scheduleDailyNotification({int? dailyMood}) async {
    if (!_initialized) {
      print("Notifications not initialized yet.");
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("User not signed in. Notifications skipped.");
      return;
    }

    try {
      // Fetch user data from Firestore
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return;

      // Only send notifications for users with role "adhd"
      final String role = userData['role'] ?? '';
      if (role.toLowerCase() != 'adhd') {
        print("User role is not 'adhd'. Notification skipped.");
        return;
      }

      final int dailyMode = userData['dailyMood'] ?? 3;

      final Map<int, List<String>> modeMessages = {
        1: [
          "Sadness doesn’t last forever, Better moments can come soon.",
          "Every sad moment passes and something good can follow.",
          "Don’t be sad, sunshine always comes back",
        ],
        2: [
          "Feeling anxious is normal, Be kind to yourself.",
          "Don’t worry, this moment will pass",
          "A short break can recharge your mind. ",
        ],
        3: [
          "Even normal days hold chances to try something new.",
          "Even a calm day can be a nice pause for your mind.",
          "A simple day can bring a gentle kind of happiness.",
        ],
        4: [
          "Let this good mood light up your day and others around you.",
          "Your smile today can make everything feel brighter.",
          "Keep your energy up! Today is a great day to do something amazing.",
        ],
        5: [
          "Enjoy this happy moment! You deserve it.",
          "Smile and share your joy with others!",
          "Stay positive, keep moving, and enjoy every moment!",
        ],
      };

      // Pick a random message based on dailyMode
      final random = Random();
      final selectedMessage =
          modeMessages[dailyMode]![random.nextInt(
            modeMessages[dailyMode]!.length,
          )];

      // Determine the scheduled time
      tz.TZDateTime scheduledDate;
      final now = tz.TZDateTime.now(tz.local);
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        13,
        55,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Notification details
      const androidDetails = AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily mood-based notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      final notificationDetails = NotificationDetails(android: androidDetails);

      // Schedule notification
      await _notificationsPlugin.zonedSchedule(
        1,
        "Daily Support ",
        selectedMessage,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'Daily Notification',
      );

      print(
        " Notification scheduled for ${currentUser.uid}: $selectedMessage at $scheduledDate",
      );
    } catch (e) {
      print(" Error scheduling notification: $e");
    }
  }
}
