import 'package:utmmart/features/shop/data/models/product_model.dart';
import 'package:utmmart/features/shop/data/models/order_model.dart';
import 'package:utmmart/features/shop/data/models/category_model.dart';

abstract class ShopRepo {
  // Product methods
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(String productId, ProductModel product);
  Future<void> deleteProduct(String productId);
  Stream<List<ProductModel>> getProducts();
  Future<ProductModel?> getProduct(String productId);
  Stream<List<ProductModel>> getProductsByCategory(String categoryId);
  Stream<List<ProductModel>> getFeaturedProducts();
  Stream<List<ProductModel>> searchProducts(String query);

  // Order methods
  Future<void> addOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Stream<List<OrderModel>> getOrders();
  Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status);
  Future<OrderModel?> getOrder(String orderId);

  // Category methods
  Future<void> addCategory(CategoryModel category);
  Stream<List<CategoryModel>> getCategories();
  Stream<List<CategoryModel>> getParentCategories();
  Stream<List<CategoryModel>> getSubCategories(String parentCategoryId);

  // Analytics methods
  Future<void> logProductView(String productId);
  Future<void> logOrderPlaced(String orderId, double total);

  // Utility methods
  Future<int> getProductCount();
  Future<int> getOrderCount();
  Future<double> getTotalRevenue();
}

