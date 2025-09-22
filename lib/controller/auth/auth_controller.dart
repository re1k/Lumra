import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumra_project/service/auth.dart';
<<<<<<< HEAD
import 'package:lumra_project/view/Account/AccountPage.dart';
=======
import 'package:lumra_project/view/Homepage/ADHDhomePageScreen.dart';
>>>>>>> 4d3f9752bed6c68c250d780e67985b1b25d8e211
import 'package:lumra_project/view/welcomepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controller/Account/UserController.dart';
class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs; // loading state for buttons

  User? get currentUser => FirebaseAuth.instance.currentUser;


  // Login
  Future<String?> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _authService.signIn(email, password);

      final uid = FirebaseAuth.instance.currentUser?.uid; // get the uid

    
      if (uid == null) {
        return "User not found.";
      }

      final snapshot = await FirebaseFirestore
          .instance // get the user data
          .collection('users')
          .doc(uid)
          .get();

      

     // final role = snapshot.data()?['role']; // get the role /edit by latifa 
      final role = snapshot.data()?['role']?.toString().toLowerCase() ?? '';

     

      Get.snackbar("Success", "You are now logged in");
      if (role == 'adhd') {
        Get.offAll(() => const ADHDHomePage()); // jana page
      } else if (role == 'caregiver') {
        Get.offAll(() => const Welcomepage()); // jana page
      }
      // else {
      //  Get.offAll(() => const Welcomepage()); ---- the admin page
      //}
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
    await _authService.signOut();
    Get.snackbar("Logged out", "You have been signed out");
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
