import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:utmmart/features/shop/data/models/cart_item_model.dart';
import 'package:utmmart/features/shop/data/models/store_item_model.dart';

/// Simple cart service that stores cart items in SharedPreferences as JSON.
///
/// Methods are written to match the usages across the UI:
/// - getCartItems(): Future<List<CartItemModel>>
/// - getCartTotal(): Future<double>
/// - getCartItemCount(): Future<int>
/// - addToCart(StoreItemModel, int): Future<bool>
/// - updateQuantity(String itemId, int): Future<bool>
/// - removeFromCart(String itemId): Future<bool>
/// - clearCart(): Future<bool>
class CartService {
  static const _kCartKey = 'cart_items';

  final SharedPreferences _prefs;

  CartService(this._prefs);

  Future<List<CartItemModel>> getCartItems() async {
    final jsonString = _prefs.getString(_kCartKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<double> getCartTotal() async {
    final items = await getCartItems();
    return items.fold<double>(0.0, (double sum, item) => sum + item.totalPrice);
  }

  Future<int> getCartItemCount() async {
    final items = await getCartItems();
    return items.fold<int>(0, (int sum, item) => sum + item.quantity);
  }

  Future<bool> addToCart(StoreItemModel storeItem, int quantity) async {
    try {
      final items = await getCartItems();

      final existingIndex = items.indexWhere(
        (i) => i.itemId == (storeItem.id ?? ''),
      );

      if (existingIndex >= 0) {
        final updated = items[existingIndex].copyWith(
          quantity: items[existingIndex].quantity + quantity,
        );
        items[existingIndex] = updated;
      } else {
        final newItem = CartItemModel.fromStoreItem(
          storeItem: storeItem,
          quantity: quantity,
        );
        items.add(newItem);
      }

      await _saveItems(items);
      return true;
    } catch (e) {
      // ignore and return false
      return false;
    }
  }

  Future<bool> updateQuantity(String itemId, int newQuantity) async {
    try {
      final items = await getCartItems();
      final index = items.indexWhere((i) => i.itemId == itemId);
      if (index == -1) return false;

      if (newQuantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: newQuantity);
      }

      await _saveItems(items);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFromCart(String itemId) async {
    try {
      final items = await getCartItems();
      items.removeWhere((i) => i.itemId == itemId);
      await _saveItems(items);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      await _prefs.remove(_kCartKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveItems(List<CartItemModel> items) async {
    final encoded = json.encode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_kCartKey, encoded);
  }
}
