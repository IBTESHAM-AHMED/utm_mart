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

    // Helper function to safely parse timestamps
    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) {
        print('⚠️ Timestamp is null, using current time');
        return DateTime.now();
      }

      print(
        '🔍 Parsing timestamp: $timestamp (type: ${timestamp.runtimeType})',
      );

      if (timestamp is Timestamp) {
        print('✅ Timestamp object detected');
        return timestamp.toDate();
      } else if (timestamp is String) {
        try {
          print('✅ String timestamp detected, parsing...');
          final parsed = DateTime.parse(timestamp);
          print('✅ Successfully parsed string timestamp: $parsed');
          return parsed;
        } catch (e) {
          print('❌ Failed to parse timestamp string: $timestamp, error: $e');
          return DateTime.now();
        }
      } else if (timestamp is DateTime) {
        print('✅ DateTime object detected');
        return timestamp;
      } else {
        print(
          '❌ Unknown timestamp type: ${timestamp.runtimeType}, value: $timestamp',
        );
        return DateTime.now();
      }
    }

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
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
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
  String get displayPrice => 'RM${itemPrice.toStringAsFixed(2)}';

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
