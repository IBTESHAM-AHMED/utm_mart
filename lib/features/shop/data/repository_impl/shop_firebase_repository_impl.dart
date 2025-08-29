import 'package:utmmart/core/services/firebase_service.dart';
import 'package:utmmart/features/shop/data/models/product_model.dart';
import 'package:utmmart/features/shop/data/models/order_model.dart';
import 'package:utmmart/features/shop/data/models/category_model.dart';
import 'package:utmmart/features/shop/domain/repository/shop_repo.dart';

class ShopFirebaseRepositoryImpl implements ShopRepo {
  final FirebaseService _firebaseService = FirebaseService();

  // Product methods
  @override
  Future<void> addProduct(ProductModel product) async {
    await _firebaseService.addProduct(product.toFirestore());
  }

  @override
  Future<void> updateProduct(String productId, ProductModel product) async {
    await _firebaseService.updateProduct(productId, product.toFirestore());
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _firebaseService.deleteProduct(productId);
  }

  @override
  Stream<List<ProductModel>> getProducts() {
    return _firebaseService.getProducts().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firebaseService.getProduct(productId);
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  @override
  Stream<List<ProductModel>> getProductsByCategory(String categoryId) {
    return _firebaseService.firestore
        .collection('products')
        .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
        .where('category', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Stream<List<ProductModel>> getFeaturedProducts() {
    return _firebaseService.firestore
        .collection('products')
        .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
        .where('isFeatured', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Stream<List<ProductModel>> searchProducts(String query) {
    query = query.toLowerCase();
    return _firebaseService.firestore
        .collection('products')
        .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .where(
                (product) =>
                    product.name.toLowerCase().contains(query) ||
                    product.description.toLowerCase().contains(query) ||
                    product.brand.toLowerCase().contains(query) ||
                    product.category.toLowerCase().contains(query),
              )
              .toList();
        });
  }

  // Order methods
  @override
  Future<void> addOrder(OrderModel order) async {
    await _firebaseService.addOrder(order.toFirestore());
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firebaseService.updateOrderStatus(
      orderId,
      status.toString().split('.').last,
    );
  }

  @override
  Stream<List<OrderModel>> getOrders() {
    return _firebaseService.getOrders().map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status) {
    return _firebaseService.firestore
        .collection('orders')
        .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Category methods
  @override
  Future<void> addCategory(CategoryModel category) async {
    await _firebaseService.addCategory(category.toFirestore());
  }

  @override
  Stream<List<CategoryModel>> getCategories() {
    return _firebaseService.getCategories().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<CategoryModel>> getParentCategories() {
    return _firebaseService.firestore
        .collection('categories')
        .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
        .where('parentCategoryId', isEqualTo: null)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Stream<List<CategoryModel>> getSubCategories(String parentCategoryId) {
    return _firebaseService.firestore
        .collection('categories')
        .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
        .where('parentCategoryId', isEqualTo: parentCategoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList();
        });
  }

  // Analytics methods
  @override
  Future<void> logProductView(String productId) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser != null) {
      await _firebaseService.logEvent('product_view', {
        'product_id': productId,
        'vendor_id': currentUser.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> logOrderPlaced(String orderId, double total) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser != null) {
      await _firebaseService.logEvent('order_placed', {
        'order_id': orderId,
        'vendor_id': currentUser.uid,
        'timestamp': DateTime.now().toIso8601String(),
        'total': total,
      });
    }
  }

  // Utility methods
  @override
  Future<int> getProductCount() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('products')
          .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting product count: $e');
      return 0;
    }
  }

  @override
  Future<int> getOrderCount() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('orders')
          .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting order count: $e');
      return 0;
    }
  }

  @override
  Future<double> getTotalRevenue() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('orders')
          .where('vendorId', isEqualTo: _firebaseService.currentUser?.uid)
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        total += order.total;
      }
      return total;
    } catch (e) {
      print('Error getting total revenue: $e');
      return 0.0;
    }
  }
}
