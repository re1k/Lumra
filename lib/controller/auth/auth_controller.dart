import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumra_project/service/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';
import "package:lumra_project/controller/ChatBoot/careGiverController.dart";
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs; // loading state for buttons
  final userRole = ''.obs; // reactive variable to hold role (adhd / caregiver)

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Login
  Future<String?> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _authService.signIn(email, password);
      final user = currentUser;
      if (user == null) return "User not found.";

      if (!user.emailVerified) {
        return "EMAIL_NOT_VERIFIED";
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) {
        return "User data not found in Firestore.";
      }

      final role = data['role']?.toString().toLowerCase();
      final name = data['firstName']?.toString();
      userRole.value = role ?? '';
      print("-------the role is $role");

      print("------the role is $name");

      //  Create ONLY the relevant chat controller for this user
      if (role == 'adhd') {
        final adhdCtrl = Get.put(AdhdChatController());
        adhdCtrl.setUserName(name);
      } else if (role == 'caregiver') {
        final caregiverCtrl = Get.put(CaregiverChatController());
        caregiverCtrl.setUserName(name);
      }

      //  Pass the name to the ADHD chat controller if role is ADHD
      /* if (role == 'adhd') {
        if (Get.isRegistered<AdhdChatController>()) {
          Get.delete<AdhdChatController>();
        }
        final adhdCtrl = Get.put(AdhdChatController());
        adhdCtrl.setUserName(name);
        print(adhdCtrl.userName);
      } else if (role == 'caregiver') {
        if (Get.isRegistered<CaregiverChatController>()) {
          Get.delete<CaregiverChatController>();
        }
        final caregiverCtrl = Get.put(CaregiverChatController());

        caregiverCtrl.setUserName(name);
      } */

      await saveUserFcmTokenIfNeeded();

      // Route once cuz AppShell decides tabs based on role
      Get.offAllNamed('/app');

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-email":
          return "The email address is not valid.";
        case "user-disabled":
        case "invalid-credential":
          return "The email or password is incorrect.";
        default:
          return "Login failed. Please try again later.";
      }
    } catch (_) {
      return "Something went wrong. Please try again.";
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Get current user's role
      final user = currentUser;
      String? role;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        role = doc.data()?['role']; // assumes you have a 'role' field

        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'fcmToken': FieldValue.delete()});
          print(' FCM token deleted on logout.');
        }
      }

      role = role?.toLowerCase();

      // Sign out
      await _authService.signOut();

      // Clear PostControllerX to ensure fresh state on next login
      if (Get.isRegistered<PostControllerX>()) {
        Get.delete<PostControllerX>(force: true);
      }

      // If user is ADHD, clear the chat controller
      if (role == 'adhd' && Get.isRegistered<AdhdChatController>()) {
        final chatCtrl = Get.find<AdhdChatController>();
        chatCtrl.clearSessionData();
        Get.delete<AdhdChatController>();
      } else {
        final chatCtrl = Get.find<CaregiverChatController>();
        chatCtrl.chatHistory.clear();
        Get.delete<CaregiverChatController>();
      }
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-email":
          return "The email address is not valid.";
        case "user-not-found":
          return "If this email exists, a reset link will be sent.";
        default:
          return "Could not send reset email. Please try again.";
      }
    } catch (_) {
      return "Something went wrong. Please try again.";
    }
  }

  // Check email
  Future<String?> checkIfEmailExists(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return "This email is not registered with us.";
      }

      return null;
    } catch (e) {
      return "Something went wrong. Please try again.";
    }
  }

  Future<void> saveUserFcmTokenIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token, 
    }, SetOptions(merge: true));
  }
}
