import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class StoreItemModel extends Equatable {
  final String? id; // Firestore document ID
  final String itemImageUrl;
  final String itemName;
  final String itemDescription;
  final double itemPrice;
  final int itemStock;
  final String itemBrand;
  final String itemCategory;
  final String? buyerUid; // Initially null, set when item is purchased
  final String sellerUid; // Current user's UID who is selling
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreItemModel({
    this.id,
    required this.itemImageUrl,
    required this.itemName,
    required this.itemDescription,
    required this.itemPrice,
    required this.itemStock,
    required this.itemBrand,
    required this.itemCategory,
    this.buyerUid,
    required this.sellerUid,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create new item for selling
  factory StoreItemModel.forSelling({
    required String itemImageUrl,
    required String itemName,
    required String itemDescription,
    required double itemPrice,
    required int itemStock,
    required String itemBrand,
    required String itemCategory,
    required String sellerUid,
  }) {
    final now = DateTime.now();
    return StoreItemModel(
      itemImageUrl: itemImageUrl,
      itemName: itemName,
      itemDescription: itemDescription,
      itemPrice: itemPrice,
      itemStock: itemStock,
      itemBrand: itemBrand,
      itemCategory: itemCategory,
      sellerUid: sellerUid,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create from Firestore document
  factory StoreItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreItemModel(
      id: doc.id,
      itemImageUrl: data['itemImageUrl'] ?? '',
      itemName: data['itemName'] ?? '',
      itemDescription: data['itemDescription'] ?? '',
      itemPrice: (data['itemPrice'] ?? 0.0).toDouble(),
      itemStock: data['itemStock'] ?? 0,
      itemBrand: data['itemBrand'] ?? '',
      itemCategory: data['itemCategory'] ?? '',
      buyerUid: data['buyerUid'],
      sellerUid: data['sellerUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'itemImageUrl': itemImageUrl,
      'itemName': itemName,
      'itemDescription': itemDescription,
      'itemPrice': itemPrice,
      'itemStock': itemStock,
      'itemBrand': itemBrand,
      'itemCategory': itemCategory,
      'buyerUid': buyerUid,
      'sellerUid': sellerUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for updates
  StoreItemModel copyWith({
    String? id,
    String? itemImageUrl,
    String? itemName,
    String? itemDescription,
    double? itemPrice,
    int? itemStock,
    String? itemBrand,
    String? itemCategory,
    String? buyerUid,
    String? sellerUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreItemModel(
      id: id ?? this.id,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      itemPrice: itemPrice ?? this.itemPrice,
      itemStock: itemStock ?? this.itemStock,
      itemBrand: itemBrand ?? this.itemBrand,
      itemCategory: itemCategory ?? this.itemCategory,
      buyerUid: buyerUid ?? this.buyerUid,
      sellerUid: sellerUid ?? this.sellerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Check if item is available for purchase
  bool get isAvailable => itemStock > 0 && buyerUid == null;

  // Get display price with currency
  String get displayPrice => '\$${itemPrice.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
    id,
    itemImageUrl,
    itemName,
    itemDescription,
    itemPrice,
    itemStock,
    itemBrand,
    itemCategory,
    buyerUid,
    sellerUid,
    createdAt,
    updatedAt,
  ];
}
