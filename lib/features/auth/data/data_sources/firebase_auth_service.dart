import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:utmmart/features/auth/data/models/user_personal_data.dart';

abstract class FirebaseAuthService {
  Future<Either<String, User>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
  });

  Future<Either<String, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<String, void>> signOut();
  Future<Either<String, void>> sendPasswordResetEmail({required String email});
  Future<UserPersonalData?> getUserPersonalData();
  Stream<User?> get authStateChanges;
  User? get currentUser;
}

class FirebaseAuthServiceImpl implements FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<Either<String, User>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      // Create user with email and password
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        return const Left('Registration failed. Please try again.');
      }

      // Update display name
      await user.updateDisplayName('$firstName $lastName');

      // Store personal data locally
      final personalData = UserPersonalData(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        address: address,
        email: email,
      );
      await _storeUserPersonalData(personalData);

      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        return const Left('Login failed. Please try again.');
      }

      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Clear personal data on sign out
      await _clearUserPersonalData();
      return const Right(null);
    } catch (e) {
      return Left('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<UserPersonalData?> getUserPersonalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final personalDataJson = prefs.getString('user_personal_data');
      if (personalDataJson != null) {
        final Map<String, dynamic> data = json.decode(personalDataJson);
        return UserPersonalData.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeUserPersonalData(UserPersonalData personalData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final personalDataJson = json.encode(personalData.toJson());
      await prefs.setString('user_personal_data', personalDataJson);
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _clearUserPersonalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_personal_data');
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Future<Either<String, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
