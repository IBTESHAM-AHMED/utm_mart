import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/features/auth/data/models/firestore_user_model.dart';

abstract class FirestoreUserService {
  Future<Either<String, void>> createUserDocument(FirestoreUserModel user);
  Future<Either<String, FirestoreUserModel>> getUserDocument(String uid);
  Future<Either<String, void>> updateUserDocument(
    String uid,
    Map<String, dynamic> updates,
  );
  Future<Either<String, void>> deleteUserDocument(String uid);
  Stream<DocumentSnapshot> getUserDocumentStream(String uid);
  Future<Either<String, void>> deleteCurrentUserAccount();
}

class FirestoreUserServiceImpl implements FirestoreUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _usersCollection = 'users';

  @override
  Future<Either<String, void>> createUserDocument(
    FirestoreUserModel user,
  ) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left('Failed to create user document: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, FirestoreUserModel>> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        return const Left('User document not found');
      }

      final user = FirestoreUserModel.fromFirestore(doc);
      return Right(user);
    } catch (e) {
      return Left('Failed to get user document: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> updateUserDocument(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Add updated timestamp
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection(_usersCollection).doc(uid).update(updates);
      return const Right(null);
    } catch (e) {
      return Left('Failed to update user document: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> deleteUserDocument(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      return const Right(null);
    } catch (e) {
      return Left('Failed to delete user document: ${e.toString()}');
    }
  }

  @override
  Stream<DocumentSnapshot> getUserDocumentStream(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots();
  }

  @override
  Future<Either<String, void>> deleteCurrentUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Left('No user logged in');
      }

      final uid = user.uid;

      // Delete Firestore document first
      final deleteDocResult = await deleteUserDocument(uid);
      if (deleteDocResult.isLeft()) {
        return deleteDocResult;
      }

      // Delete Firebase Auth user
      await user.delete();

      return const Right(null);
    } catch (e) {
      return Left('Failed to delete user account: ${e.toString()}');
    }
  }

  // Helper methods for current user
  Future<Either<String, FirestoreUserModel>> getCurrentUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Left('No user logged in');
    }

    return await getUserDocument(user.uid);
  }

  Future<Either<String, void>> updateCurrentUserDocument(
    Map<String, dynamic> updates,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Left('No user logged in');
    }

    return await updateUserDocument(user.uid, updates);
  }

  Stream<DocumentSnapshot>? getCurrentUserDocumentStream() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return getUserDocumentStream(user.uid);
  }
}
