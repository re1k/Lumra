import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumra_project/service/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart";
//import "package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart;
import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs; // loading state for buttons

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
      }

      role = role?.toLowerCase();

      // Sign out
      await _authService.signOut();

      // If user is ADHD, clear the chat controller
      if (role == 'adhd' && Get.isRegistered<ChatController>()) {
        final chatCtrl = Get.find<ChatController>();
        chatCtrl.chatHistory.clear();
        Get.delete<ChatController>();
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
}
