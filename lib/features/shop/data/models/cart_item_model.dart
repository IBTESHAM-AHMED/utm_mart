import 'package:equatable/equatable.dart';
import 'package:utmmart/features/shop/data/models/store_item_model.dart';

class CartItemModel extends Equatable {
  final String itemId; // Store item ID
  final String itemName;
  final String itemImageUrl;
  final double itemPrice;
  final String itemBrand;
  final String itemCategory;
  final String sellerUid;
  final int quantity;
  final DateTime addedAt;

  const CartItemModel({
    required this.itemId,
    required this.itemName,
    required this.itemImageUrl,
    required this.itemPrice,
    required this.itemBrand,
    required this.itemCategory,
    required this.sellerUid,
    required this.quantity,
    required this.addedAt,
  });

  // Create cart item from store item
  factory CartItemModel.fromStoreItem({
    required StoreItemModel storeItem,
    required int quantity,
  }) {
    return CartItemModel(
      itemId: storeItem.id ?? '',
      itemName: storeItem.itemName,
      itemImageUrl: storeItem.itemImageUrl,
      itemPrice: storeItem.itemPrice,
      itemBrand: storeItem.itemBrand,
      itemCategory: storeItem.itemCategory,
      sellerUid: storeItem.sellerUid,
      quantity: quantity,
      addedAt: DateTime.now(),
    );
  }

  // Create from JSON (for session storage)
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      itemImageUrl: json['itemImageUrl'] ?? '',
      itemPrice: (json['itemPrice'] ?? 0.0).toDouble(),
      itemBrand: json['itemBrand'] ?? '',
      itemCategory: json['itemCategory'] ?? '',
      sellerUid: json['sellerUid'] ?? '',
      quantity: json['quantity'] ?? 1,
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Convert to JSON (for session storage)
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemImageUrl': itemImageUrl,
      'itemPrice': itemPrice,
      'itemBrand': itemBrand,
      'itemCategory': itemCategory,
      'sellerUid': sellerUid,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Get total price for this cart item
  double get totalPrice => itemPrice * quantity;

  // Get display price
  String get displayPrice => 'RM${itemPrice.toStringAsFixed(2)}';
  String get displayTotalPrice => 'RM${totalPrice.toStringAsFixed(2)}';

  // Copy with method for quantity updates
  CartItemModel copyWith({
    String? itemId,
    String? itemName,
    String? itemImageUrl,
    double? itemPrice,
    String? itemBrand,
    String? itemCategory,
    String? sellerUid,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      itemPrice: itemPrice ?? this.itemPrice,
      itemBrand: itemBrand ?? this.itemBrand,
      itemCategory: itemCategory ?? this.itemCategory,
      sellerUid: sellerUid ?? this.sellerUid,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
    itemId,
    itemName,
    itemImageUrl,
    itemPrice,
    itemBrand,
    itemCategory,
    sellerUid,
    quantity,
    addedAt,
  ];
}
