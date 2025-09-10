import 'package:cloud_firestore/cloud_firestore.dart';

class AuctionModel {
  final String? id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String sellerUid;
  final String sellerName;
  final double startingPrice;
  final double currentBid;
  final double? buyNowPrice;
  final DateTime startTime;
  final DateTime endTime;
  final List<BidModel> bids;
  final String status; // 'active', 'ended', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  AuctionModel({
    this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.sellerUid,
    required this.sellerName,
    required this.startingPrice,
    required this.currentBid,
    this.buyNowPrice,
    required this.startTime,
    required this.endTime,
    this.bids = const [],
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore document
  factory AuctionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuctionModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      sellerUid: data['sellerUid'] ?? '',
      sellerName: data['sellerName'] ?? '',
      startingPrice: (data['startingPrice'] ?? 0).toDouble(),
      currentBid: (data['currentBid'] ?? 0).toDouble(),
      buyNowPrice: data['buyNowPrice']?.toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      bids: (data['bids'] as List<dynamic>? ?? [])
          .map((bid) => BidModel.fromMap(bid))
          .toList(),
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'sellerUid': sellerUid,
      'sellerName': sellerName,
      'startingPrice': startingPrice,
      'currentBid': currentBid,
      'buyNowPrice': buyNowPrice,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'bids': bids.map((bid) => bid.toMap()).toList(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Check if auction is active
  bool get isActive {
    final now = DateTime.now();
    return status == 'active' &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);
  }

  // Check if auction has ended
  bool get hasEnded {
    final now = DateTime.now();
    return status == 'ended' || now.isAfter(endTime);
  }

  // Get time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  // Get highest bidder
  BidModel? get highestBid {
    if (bids.isEmpty) return null;
    return bids.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  // Create a copy with updated fields
  AuctionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    String? sellerUid,
    String? sellerName,
    double? startingPrice,
    double? currentBid,
    double? buyNowPrice,
    DateTime? startTime,
    DateTime? endTime,
    List<BidModel>? bids,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuctionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      sellerUid: sellerUid ?? this.sellerUid,
      sellerName: sellerName ?? this.sellerName,
      startingPrice: startingPrice ?? this.startingPrice,
      currentBid: currentBid ?? this.currentBid,
      buyNowPrice: buyNowPrice ?? this.buyNowPrice,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      bids: bids ?? this.bids,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AuctionModel(id: $id, title: $title, currentBid: $currentBid, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuctionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BidModel {
  final String bidderUid;
  final String bidderName;
  final double amount;
  final DateTime timestamp;

  BidModel({
    required this.bidderUid,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });

  factory BidModel.fromMap(Map<String, dynamic> map) {
    return BidModel(
      bidderUid: map['bidderUid'] ?? '',
      bidderName: map['bidderName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bidderUid': bidderUid,
      'bidderName': bidderName,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  String toString() {
    return 'BidModel(bidderName: $bidderName, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BidModel &&
        other.bidderUid == bidderUid &&
        other.amount == amount &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return bidderUid.hashCode ^ amount.hashCode ^ timestamp.hashCode;
  }
}
