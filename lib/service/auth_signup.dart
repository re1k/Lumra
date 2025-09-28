import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create new account in Firebase Auth
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final String normalized = email.trim().toLowerCase();
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: normalized,
            password: password,
          );
      return userCredential;
    } on FirebaseAuthException {
      // Re-throw the FirebaseAuthException to preserve the error code
      rethrow;
    }
  }

  /// Save user data to Firestore
  static Future<void> saveUserToFirestore({
    required String uid,
    required String role,
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    required DateTime? dob,
    required int totalPoints,
    String? linkedUserId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'gender': gender,
        'dob': dob != null ? Timestamp.fromDate(dob) : null,
        'linkedUserId': linkedUserId,
      };

      // Caregiver does not have points: omit the field entirely.
      if (role.toLowerCase() != 'caregiver') {
        data['totalPoints'] = totalPoints;
      }

      await _firestore.collection('users').doc(uid).set(data);
    } catch (e) {
      throw Exception('Firestore Error: $e');
    }
  }

  /// Create complete account (Auth + Firestore + Email Verification)
  static Future<bool> createCompleteAccount({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime? dob,
    required int totalPoints,
  }) async {
    try {
      final String normalized = email.trim().toLowerCase();
      // 1. Create account in Firebase Auth
      final UserCredential userCredential =
          await createUserWithEmailAndPassword(
            email: normalized,
            password: password,
          );

      if (userCredential.user != null) {
        // 2. Save data to Firestore
        await saveUserToFirestore(
          uid: userCredential.user!.uid,
          role: role,
          firstName: firstName,
          lastName: lastName,
          email: normalized,
          gender: gender,
          dob: dob,
          totalPoints: totalPoints,
          linkedUserId: null,
        );

        // 3. Send email verification
        await userCredential.user?.sendEmailVerification();

        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'email-already-in-use') {
        // Throw code string so upstream can detect reliably
        throw Exception('email-already-in-use');
      } else if (e.code == 'weak-password') {
        throw Exception('weak-password');
      } else if (e.code == 'invalid-email') {
        throw Exception('invalid-email');
      } else {
        throw Exception('auth-error: ${e.message}');
      }
    } catch (e) {
      throw Exception('general-error: $e');
    }
  }

  /// Create account with email verification (Auth only, no Firestore until verified)
  static Future<bool> createAccountWithVerification({
    required String email,
    required String password,
  }) async {
    try {
      final String normalized = email.trim().toLowerCase();
      // 1. Create account in Firebase Auth only
      final UserCredential userCredential =
          await createUserWithEmailAndPassword(
            email: normalized,
            password: password,
          );

      if (userCredential.user != null) {
        // 2. Send email verification immediately
        await userCredential.user?.sendEmailVerification();
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'email-already-in-use') {
        // Throw code string so upstream can detect reliably
        throw Exception('email-already-in-use');
      } else if (e.code == 'weak-password') {
        throw Exception('weak-password');
      } else if (e.code == 'invalid-email') {
        throw Exception('invalid-email');
      } else {
        throw Exception('auth-error: ${e.message}');
      }
    } catch (e) {
      throw Exception('general-error: $e');
    }
  }

  /// Save user data to Firestore after email verification
  static Future<bool> saveUserDataAfterVerification({
    required String role,
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime? dob,
    required int totalPoints,
    String? linkedUserId,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user.');
      }

      // Check if email is verified
      if (!user.emailVerified) {
        throw Exception('Email not verified yet.');
      }

      // Save data to Firestore
      await saveUserToFirestore(
        uid: user.uid,
        role: role,
        firstName: firstName,
        lastName: lastName,
        email: user.email!,
        gender: gender,
        dob: dob,
        totalPoints: totalPoints,
        linkedUserId: linkedUserId,
      );

      return true;
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Update the current user's linkedUserId field in Firestore.
  static Future<void> updateLinkedUserIdForCurrentUser(
    String linkedUserId,
  ) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user.');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'linkedUserId': linkedUserId,
      });
    } catch (e) {
      throw Exception('Failed to update linkedUserId: $e');
    }
  }

  /// Create a caregiver account and set linkedUserId in a single operation.
  static Future<bool> createCaregiverAccountWithLink({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime? dob,
    required String linkedUserId,
  }) async {
    try {
      final String normalized = email.trim().toLowerCase();
      // 1. Create account in Firebase Auth
      final UserCredential userCredential =
          await createUserWithEmailAndPassword(
            email: normalized,
            password: password,
          );

      if (userCredential.user != null) {
        // 2. Save caregiver data to Firestore with the linkedUserId
        await saveUserToFirestore(
          uid: userCredential.user!.uid,
          role: 'caregiver',
          firstName: firstName,
          lastName: lastName,
          email: normalized,
          gender: gender,
          dob: dob,
          totalPoints: 0,
          linkedUserId: linkedUserId,
        );

        // 3. Update the ADHD user's document with caregiver's UID (reverse linking)
        await _firestore.collection('users').doc(linkedUserId).update({
          'linkedUserId': userCredential.user!.uid,
        });

        // 4. Send email verification
        await userCredential.user?.sendEmailVerification();

        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'The email address is already in use by another account.',
        );
      } else if (e.code == 'weak-password') {
        throw Exception('weak-password');
      } else if (e.code == 'invalid-email') {
        throw Exception('invalid-email');
      } else {
        throw Exception('auth-error: ${e.message}');
      }
    } catch (e) {
      throw Exception('general-error: $e');
    }
  }

  /// Create caregiver account with email verification (Auth only, no Firestore until verified)
  static Future<bool> createCaregiverAccountWithVerification({
    required String email,
    required String password,
  }) async {
    try {
      final String normalized = email.trim().toLowerCase();
      // 1. Create account in Firebase Auth only
      final UserCredential userCredential =
          await createUserWithEmailAndPassword(
            email: normalized,
            password: password,
          );

      if (userCredential.user != null) {
        // 2. Send email verification immediately
        await userCredential.user?.sendEmailVerification();
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'The email address is already in use by another account.',
        );
      } else if (e.code == 'weak-password') {
        throw Exception('weak-password');
      } else if (e.code == 'invalid-email') {
        throw Exception('invalid-email');
      } else {
        throw Exception('auth-error: ${e.message}');
      }
    } catch (e) {
      throw Exception('general-error: $e');
    }
  }

  /// Check if an email is already in use (returns true if taken)
  // Note: Some SDK versions deprecate this; if unavailable, callers should rely on createAccount catch
  // Keeping the method here commented for reference; not used now to avoid build errors.
  // static Future<bool> isEmailInUse(String email) async {
  //   try {
  //     final List<String> methods =
  //         await _auth.fetchSignInMethodsForEmail(email);
  //     return methods.isNotEmpty;
  //   } on FirebaseAuthException catch (_) {
  //     return false;
  //   }
  // }

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Check authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
