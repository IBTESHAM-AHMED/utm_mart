class AuctionEntity {
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
  final List<BidEntity> bids;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AuctionEntity({
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
  BidEntity? get highestBid {
    if (bids.isEmpty) return null;
    return bids.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  @override
  String toString() {
    return 'AuctionEntity(id: $id, title: $title, currentBid: $currentBid, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuctionEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BidEntity {
  final String bidderUid;
  final String bidderName;
  final double amount;
  final DateTime timestamp;

  BidEntity({
    required this.bidderUid,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'BidEntity(bidderName: $bidderName, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BidEntity &&
        other.bidderUid == bidderUid &&
        other.amount == amount &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return bidderUid.hashCode ^ amount.hashCode ^ timestamp.hashCode;
  }
}
