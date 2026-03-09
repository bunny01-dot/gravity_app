import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_sign_in/google_sign_in.dart';



class AuthService {

  // Singleton instance

  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();



  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();



  // Get current user

  User? get currentUser => _auth.currentUser;



  // Stream of auth changes

  Stream<User?> get authStateChanges => _auth.authStateChanges();



  // Sign Up

  Future<User?> signUp(String email, String password, String name) async {

    try {

      debugPrint("Attempting sign-up for ${_maskEmail(email)}");



      // Validate inputs

      if (email.isEmpty || password.isEmpty) {

        throw "Email and password cannot be empty";

      }



      if (password.length < 6) {

        throw "Password must be at least 6 characters long";

      }



      if (!email.contains('@')) {

        throw "Please enter a valid email address";

      }



      UserCredential result = await _auth.createUserWithEmailAndPassword(

        email: email,

        password: password,

      );



      // Create user document in Firestore

      if (result.user != null) {

        final role = getUserRole(email);

        await FirebaseFirestore.instance

            .collection('users')

            .doc(result.user!.uid)

            .set({

              'uid': result.user!.uid,

              'email': email,

              'name': name,

              'role': role,

              'createdAt': FieldValue.serverTimestamp(),

              'lastActive': FieldValue.serverTimestamp(),

            });

      }



      debugPrint("Sign-up successful for ${_maskEmail(result.user?.email)}");

      return result.user;

    } on FirebaseAuthException catch (e) {

      debugPrint("Firebase Sign Up Error Code: ${e.code}");

      debugPrint("Firebase Sign Up Error Message: ${e.message}");



      // Handle specific Firebase error codes

      switch (e.code) {

        case 'weak-password':

          throw "The password provided is too weak. Use at least 6 characters.";

        case 'email-already-in-use':

          throw "An account already exists with this email address.";

        case 'invalid-email':

          throw "The email address is not valid.";

        case 'operation-not-allowed':

          throw "Email/password accounts are not enabled. Please contact support.";

        case 'network-request-failed':

          throw "Network error. Please check your internet connection.";

        default:

          throw e.message ?? "Sign up failed. Please try again.";

      }

    } catch (e) {

      debugPrint("Unexpected error during sign up: $e");

      if (e is String) {

        rethrow;

      }

      throw "An unexpected error occurred: ${e.toString()}";

    }

  }



  // Sign In

  Future<User?> signIn(String email, String password) async {

    try {

      UserCredential result = await _auth.signInWithEmailAndPassword(

        email: email,

        password: password,

      );



      // Update last active

      if (result.user != null) {

        await FirebaseFirestore.instance

            .collection('users')

            .doc(result.user!.uid)

            .update({'lastActive': FieldValue.serverTimestamp()})

            .catchError((e) {

              // Ignore error if doc doesn't exist (e.g. legacy user)

              debugPrint("Error updating lastActive: $e");

            });

      }



      return result.user;

    } on FirebaseAuthException catch (e) {

      debugPrint("Firebase Sign In Error: ${e.message}");

      throw e.message ?? "Login failed";

    } catch (e) {

      throw "An unexpected error occurred.";

    }

  }



  // Sign In with Google

  Future<User?> signInWithGoogle() async {

    try {

      debugPrint(" Initiating Google Sign-In...");



      // Ensure previous session is cleared

      await _googleSignIn.signOut();



      // Trigger the Google Sign-In flow

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();



      if (googleUser == null) {

        // User canceled the sign-in

        debugPrint("[WARN] Google Sign-In canceled by user");

        return null;

      }



      debugPrint("Google account selected: ${_maskEmail(googleUser.email)}");



      // Obtain the auth details from the request

      final GoogleSignInAuthentication googleAuth =

          await googleUser.authentication;



      // Validate we got the tokens

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {

        debugPrint("Error: Missing authentication tokens");

        throw "Failed to get authentication tokens from Google. Please try again.";

      }



      debugPrint("OK: Got authentication tokens");



      // Create a new credential

      final credential = GoogleAuthProvider.credential(

        accessToken: googleAuth.accessToken,

        idToken: googleAuth.idToken,

      );



      debugPrint("[REFRESH] Signing in to Firebase...");



      // Sign in to Firebase with the Google credential

      UserCredential result = await _auth.signInWithCredential(credential);



      if (result.user == null) {

        debugPrint("Error: Firebase returned null user");

        throw "Authentication succeeded but user data is missing. Please try again.";

      }



      debugPrint("OK: Firebase sign-in successful");



      // Create or update user document in Firestore

      try {

        final role = getUserRole(result.user!.email);

        final userDoc = FirebaseFirestore.instance

            .collection('users')

            .doc(result.user!.uid);



        // Check if user document exists

        final docSnapshot = await userDoc.get();



        if (!docSnapshot.exists) {

          // New user - create document

          await userDoc.set({

            'uid': result.user!.uid,

            'email': result.user!.email,

            'name': result.user!.displayName ?? 'User',

            'photo_url': result.user!.photoURL ?? '',

            'photoUrl': result.user!.photoURL ?? '',

            'photoURL': result.user!.photoURL,

            'role': role,

            'provider': 'google',

            'createdAt': FieldValue.serverTimestamp(),

            'lastActive': FieldValue.serverTimestamp(),

          });

          debugPrint(

            "Created new user document for ${_maskEmail(result.user!.email)}",

          );

        } else {

          // Existing user - update last active

          await userDoc.update({

            'lastActive': FieldValue.serverTimestamp(),

            'photo_url': result.user!.photoURL ?? '',

            'photoUrl': result.user!.photoURL ?? '',

            'photoURL': result.user!.photoURL, // Update in case it changed

          });

          debugPrint(

            "Updated existing user ${_maskEmail(result.user!.email)}",

          );

        }

      } catch (firestoreError) {

        // Don't fail the sign-in if Firestore update fails

        debugPrint(

          " Firestore update failed (non-critical): $firestoreError",

        );

      }



      debugPrint(

        "Google Sign-In complete for ${_maskEmail(result.user?.email)}",

      );

      return result.user;

    } on FirebaseAuthException catch (e) {

      debugPrint("Error: Firebase Auth Error during Google Sign-In");

      debugPrint("   Code: ${e.code}");

      debugPrint("   Message: ${e.message}");



      switch (e.code) {

        case 'account-exists-with-different-credential':

          throw "An account already exists with the same email. Try signing in with email/password.";

        case 'invalid-credential':

          throw "The credential is invalid or expired. Please try again.";

        case 'operation-not-allowed':

          throw "Google Sign-In is not enabled. Please contact support.";

        case 'user-disabled':

          throw "This account has been disabled.";

        case 'network-request-failed':

          throw "Network error. Please check your internet connection.";

        default:

          throw e.message ?? "Google Sign-In failed. Please try again.";

      }

    } catch (e) {

      debugPrint("Error: Unexpected error during Google Sign-In");

      debugPrint("   Type: ${e.runtimeType}");

      debugPrint("   Details: $e");



      // Check for common issues

      if (e.toString().contains('PlatformException')) {

        throw "Platform error: Please ensure Google Play Services is installed and up-to-date.";

      } else if (e.toString().contains('SIGN_IN_FAILED')) {

        throw "Sign-in failed. Please check your internet connection and try again.";

      } else if (e.toString().contains('API')) {

        throw "Google API error. Please ensure Google Sign-In is configured correctly in Firebase Console.";

      }



      if (e is String) {

        rethrow;

      }

      throw "An unexpected error occurred during Google Sign-In. Please try again or use email/password.";

    }

  }



  // Sign Out

  Future<void> signOut() async {

    await Future.wait([

      _auth.signOut(),

      _googleSignIn.signOut(), // Also sign out from Google

    ]);

  }



  // Check if user is a teacher

  bool isTeacher(String? email) {

    if (email == null) return false;

    // List of teacher emails

    const teacherEmails = ['teacher@english.com'];

    return teacherEmails.contains(email.toLowerCase());

  }



  // Get user role

  String getUserRole(String? email) {

    return isTeacher(email) ? 'teacher' : 'student';

  }



  String _maskEmail(String? email) {

    final raw = (email ?? '').trim();

    if (raw.isEmpty || !raw.contains('@')) return 'unknown';

    final parts = raw.split('@');

    final local = parts.first;

    final domain = parts.length > 1 ? parts[1] : '';

    if (local.isEmpty) return '***@$domain';

    if (local.length == 1) return '${local[0]}***@$domain';

    return '${local[0]}***${local[local.length - 1]}@$domain';

  }

}



