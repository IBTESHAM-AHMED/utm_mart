import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:utmmart/core/utils/exceptions/firebase_exceptions.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;
  FirebaseAnalytics get analytics => _analytics;

  // Current user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Save token to user document
        await _saveFcmToken(token);
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveFcmToken(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      });
    } catch (e) {
      throw TFirebaseException('Failed to initialize Firebase services: $e');
    }
  }

  // Save FCM token to user document
  Future<void> _saveFcmToken(String token) async {
    try {
      if (currentUser != null) {
        // Use set with merge: true to create document if it doesn't exist
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM token saved successfully');
      }
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  // Authentication methods
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseException(_getAuthErrorMessage(e.code));
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseException(_getAuthErrorMessage(e.code));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw TFirebaseException('Failed to sign out: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseException(_getAuthErrorMessage(e.code));
    }
  }

  // Firestore methods for products
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _firestore.collection('products').add({
        ...productData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'vendorId': currentUser?.uid,
      });
    } catch (e) {
      throw TFirebaseException('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        ...productData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw TFirebaseException('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw TFirebaseException('Failed to delete product: $e');
    }
  }

  Stream<QuerySnapshot> getProducts() {
    return _firestore
        .collection('products')
        .where('vendorId', isEqualTo: currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getProduct(String productId) async {
    try {
      return await _firestore.collection('products').doc(productId).get();
    } catch (e) {
      throw TFirebaseException('Failed to get product: $e');
    }
  }

  // Firestore methods for orders
  Future<void> addOrder(Map<String, dynamic> orderData) async {
    try {
      await _firestore.collection('orders').add({
        ...orderData,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'vendorId': currentUser?.uid,
      });
    } catch (e) {
      throw TFirebaseException('Failed to add order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw TFirebaseException('Failed to update order status: $e');
    }
  }

  Stream<QuerySnapshot> getOrders() {
    return _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Firestore methods for categories
  Future<void> addCategory(Map<String, dynamic> categoryData) async {
    try {
      await _firestore.collection('categories').add({
        ...categoryData,
        'createdAt': FieldValue.serverTimestamp(),
        'vendorId': currentUser?.uid,
      });
    } catch (e) {
      throw TFirebaseException('Failed to add category: $e');
    }
  }

  Stream<QuerySnapshot> getCategories() {
    return _firestore
        .collection('categories')
        .where('vendorId', isEqualTo: currentUser?.uid)
        .orderBy('name')
        .snapshots();
  }

  // Storage methods for images
  Future<String> uploadProductImage(String imagePath, String productId) async {
    try {
      final ref = _storage.ref().child(
        'products/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadTask = ref.putFile(File(imagePath));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw TFirebaseException('Failed to upload image: $e');
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw TFirebaseException('Failed to delete image: $e');
    }
  }

  // Analytics methods
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      print('Failed to log analytics event: $e');
    }
  }

  // Helper method for auth error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
