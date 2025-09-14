import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';

class AuctionFirestoreService {
  final FirebaseService _firebaseService = sl<FirebaseService>();

  // Get all active auctions
  Stream<QuerySnapshot> getActiveAuctionsStream() {
    return _firebaseService.firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Get auctions by category
  Stream<QuerySnapshot> getAuctionsByCategoryStream(String category) {
    return _firebaseService.firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .where('category', isEqualTo: category)
        .snapshots();
  }

  // Search auctions
  Stream<QuerySnapshot> searchAuctionsStream(String query) {
    return _firebaseService.firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Get auction by ID
  Future<AuctionModel?> getAuctionById(String auctionId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('auctions')
          .doc(auctionId)
          .get();

      if (doc.exists) {
        return AuctionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get auction: $e');
    }
  }

  // Create new auction
  Future<String> createAuction(AuctionModel auction) async {
    try {
      final docRef = await _firebaseService.firestore
          .collection('auctions')
          .add(auction.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create auction: $e');
    }
  }

  // Update auction
  Future<void> updateAuction(String auctionId, AuctionModel auction) async {
    try {
      await _firebaseService.firestore
          .collection('auctions')
          .doc(auctionId)
          .update(auction.toFirestore());
    } catch (e) {
      throw Exception('Failed to update auction: $e');
    }
  }

  // Place a bid
  Future<void> placeBid(String auctionId, BidModel bid) async {
    try {
      final auctionRef = _firebaseService.firestore
          .collection('auctions')
          .doc(auctionId);

      await _firebaseService.firestore.runTransaction((transaction) async {
        final auctionDoc = await transaction.get(auctionRef);

        if (!auctionDoc.exists) {
          throw Exception('Auction not found');
        }

        final auction = AuctionModel.fromFirestore(auctionDoc);

        if (auction.hasEnded) {
          throw Exception('Auction has ended');
        }

        if (bid.amount <= auction.currentBid) {
          throw Exception('Bid must be higher than current bid');
        }

        final updatedBids = [...auction.bids, bid];
        final updatedAuction = auction.copyWith(
          currentBid: bid.amount,
          bids: updatedBids,
          updatedAt: DateTime.now(),
        );

        transaction.update(auctionRef, updatedAuction.toFirestore());
      });
    } catch (e) {
      throw Exception('Failed to place bid: $e');
    }
  }

  // Buy now
  Future<void> buyNow(
    String auctionId,
    String buyerUid,
    String buyerName,
  ) async {
    try {
      final auctionRef = _firebaseService.firestore
          .collection('auctions')
          .doc(auctionId);

      await _firebaseService.firestore.runTransaction((transaction) async {
        final auctionDoc = await transaction.get(auctionRef);

        if (!auctionDoc.exists) {
          throw Exception('Auction not found');
        }

        final auction = AuctionModel.fromFirestore(auctionDoc);

        if (auction.hasEnded) {
          throw Exception('Auction has ended');
        }

        if (auction.buyNowPrice == null) {
          throw Exception('Buy now not available for this auction');
        }

        final buyNowBid = BidModel(
          bidderUid: buyerUid,
          bidderName: buyerName,
          amount: auction.buyNowPrice!,
          timestamp: DateTime.now(),
        );

        final updatedBids = [...auction.bids, buyNowBid];
        final updatedAuction = auction.copyWith(
          currentBid: auction.buyNowPrice!,
          bids: updatedBids,
          status: 'ended',
          updatedAt: DateTime.now(),
        );

        transaction.update(auctionRef, updatedAuction.toFirestore());
      });
    } catch (e) {
      throw Exception('Failed to buy now: $e');
    }
  }

  // End auction and create order for highest bidder
  Future<void> endAuction(String auctionId) async {
    try {
      final auctionRef = _firebaseService.firestore
          .collection('auctions')
          .doc(auctionId);

      await _firebaseService.firestore.runTransaction((transaction) async {
        final auctionDoc = await transaction.get(auctionRef);

        if (!auctionDoc.exists) {
          throw Exception('Auction not found');
        }

        final auction = AuctionModel.fromFirestore(auctionDoc);

        if (auction.status != 'active') {
          throw Exception('Auction is not active');
        }

        // Update auction status
        transaction.update(auctionRef, {
          'status': 'ended',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create order for highest bidder if there are bids
        if (auction.bids.isNotEmpty) {
          final highestBid = auction.highestBid!;
          await _createOrderFromAuction(auction, highestBid);
        }
      });
    } catch (e) {
      throw Exception('Failed to end auction: $e');
    }
  }

  // Create order from auction for highest bidder
  Future<void> _createOrderFromAuction(
    AuctionModel auction,
    BidModel highestBid,
  ) async {
    try {
      // Create order document
      final orderData = {
        'customerId': highestBid.bidderUid,
        'customerName': highestBid.bidderName,
        'sellerUid': auction.sellerUid,
        'sellerName': auction.sellerName,
        'items': [
          {
            'itemId': auction.id,
            'itemName': auction.title,
            'itemImageUrl': auction.imageUrl,
            'itemPrice': highestBid.amount,
            'quantity': 1,
            'totalPrice': highestBid.amount,
          },
        ],
        'subtotal': highestBid.amount,
        'tax': 0.0, // No tax for auction items
        'total': highestBid.amount,
        'status': 'pending',
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'auctionId': auction.id,
        'isAuctionOrder': true,
      };

      await _firebaseService.firestore.collection('orders').add(orderData);

      print(
        '✅ Order created for auction ${auction.id} - Winner: ${highestBid.bidderName}',
      );
    } catch (e) {
      print('❌ Error creating order from auction: $e');
      throw Exception('Failed to create order from auction: $e');
    }
  }

  // Get user's auctions
  Stream<QuerySnapshot> getUserAuctionsStream(String sellerUid) {
    return _firebaseService.firestore
        .collection('auctions')
        .where('sellerUid', isEqualTo: sellerUid)
        .snapshots();
  }

  // Get user's active auctions
  Stream<QuerySnapshot> getUserActiveAuctionsStream(String sellerUid) {
    return _firebaseService.firestore
        .collection('auctions')
        .where('sellerUid', isEqualTo: sellerUid)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Get user's closed auctions
  Stream<QuerySnapshot> getUserClosedAuctionsStream(String sellerUid) {
    return _firebaseService.firestore
        .collection('auctions')
        .where('sellerUid', isEqualTo: sellerUid)
        .where('status', isEqualTo: 'ended')
        .snapshots();
  }

  // Get user's bids
  Stream<QuerySnapshot> getUserBidsStream(String bidderUid) {
    return _firebaseService.firestore
        .collection('auctions')
        .where('bids', arrayContains: {'bidderUid': bidderUid})
        .snapshots();
  }

  // Delete auction
  Future<void> deleteAuction(String auctionId) async {
    try {
      await _firebaseService.firestore
          .collection('auctions')
          .doc(auctionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete auction: $e');
    }
  }

  // Check and end expired auctions
  Future<void> checkAndEndExpiredAuctions() async {
    try {
      final now = DateTime.now();
      final expiredAuctions = await _firebaseService.firestore
          .collection('auctions')
          .where('status', isEqualTo: 'active')
          .where('endTime', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in expiredAuctions.docs) {
        try {
          await endAuction(doc.id);
          print('✅ Ended expired auction: ${doc.id}');
        } catch (e) {
          print('❌ Error ending expired auction ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('❌ Error checking expired auctions: $e');
    }
  }

  // Get auctions that need to be ended (for background processing)
  Future<List<String>> getExpiredAuctionIds() async {
    try {
      final now = DateTime.now();
      final expiredAuctions = await _firebaseService.firestore
          .collection('auctions')
          .where('status', isEqualTo: 'active')
          .where('endTime', isLessThan: Timestamp.fromDate(now))
          .get();

      return expiredAuctions.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Error getting expired auction IDs: $e');
      return [];
    }
  }
}
