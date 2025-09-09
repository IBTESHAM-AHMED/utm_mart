import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/features/shop/data/models/store_item_model.dart';

abstract class StoreFirestoreService {
  Future<Either<String, void>> addStoreItem(StoreItemModel item);
  Future<Either<String, List<StoreItemModel>>> getAllStoreItems();
  Future<Either<String, List<StoreItemModel>>> getUserStoreItems(
    String sellerUid,
  );
  Future<Either<String, void>> updateStoreItem(
    String itemId,
    Map<String, dynamic> updates,
  );
  Future<Either<String, void>> deleteStoreItem(String itemId);
  Stream<QuerySnapshot> getStoreItemsStream();
}

class StoreFirestoreServiceImpl implements StoreFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _storeCollection = 'store';

  @override
  Future<Either<String, void>> addStoreItem(StoreItemModel item) async {
    try {
      await _firestore.collection(_storeCollection).add(item.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left('Failed to add store item: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<StoreItemModel>>> getAllStoreItems() async {
    try {
      print('🔍 Querying store collection...');
      final querySnapshot = await _firestore
          .collection(_storeCollection)
          .orderBy('createdAt', descending: true)
          .get();

      print(
        '📊 Found ${querySnapshot.docs.length} documents in store collection',
      );

      final items = querySnapshot.docs.map((doc) {
        print('📄 Document ID: ${doc.id}');
        print('📄 Document data: ${doc.data()}');
        print('📄 createdAt type: ${doc.data()['createdAt']?.runtimeType}');
        print('📄 updatedAt type: ${doc.data()['updatedAt']?.runtimeType}');
        return StoreItemModel.fromFirestore(doc);
      }).toList();

      print('✅ Successfully parsed ${items.length} items');
      return Right(items);
    } catch (e) {
      print('❌ Error in getAllStoreItems: $e');
      return Left('Failed to get store items: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<StoreItemModel>>> getUserStoreItems(
    String sellerUid,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_storeCollection)
          .where('sellerUid', isEqualTo: sellerUid)
          .orderBy('createdAt', descending: true)
          .get();

      final items = querySnapshot.docs
          .map((doc) => StoreItemModel.fromFirestore(doc))
          .toList();

      return Right(items);
    } catch (e) {
      return Left('Failed to get user store items: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> updateStoreItem(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection(_storeCollection).doc(itemId).update(updates);

      return const Right(null);
    } catch (e) {
      return Left('Failed to update store item: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> deleteStoreItem(String itemId) async {
    try {
      await _firestore.collection(_storeCollection).doc(itemId).delete();
      return const Right(null);
    } catch (e) {
      return Left('Failed to delete store item: ${e.toString()}');
    }
  }

  @override
  Stream<QuerySnapshot> getStoreItemsStream() {
    return _firestore
        .collection(_storeCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Helper method to get current user's items stream
  Stream<QuerySnapshot>? getCurrentUserItemsStream() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection(_storeCollection)
        .where('sellerUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Helper method to add item for current user
  Future<Either<String, void>> addCurrentUserItem(StoreItemModel item) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Left('No user logged in');
    }

    final itemWithSeller = item.copyWith(sellerUid: user.uid);
    return await addStoreItem(itemWithSeller);
  }
}
