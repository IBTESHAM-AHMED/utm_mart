import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/notifications/data/models/notification_model.dart';
import 'package:utmmart/features/notifications/data/services/notification_service.dart';

class AuctionFirestoreService {
  final FirebaseService _firebaseService = sl<FirebaseService>();
  final NotificationService _notificationService = NotificationService();

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

      AuctionModel? auction;

      await _firebaseService.firestore.runTransaction((transaction) async {
        final auctionDoc = await transaction.get(auctionRef);

        if (!auctionDoc.exists) {
          throw Exception('Auction not found');
        }

        auction = AuctionModel.fromFirestore(auctionDoc);

        if (auction!.hasEnded) {
          throw Exception('Auction has ended');
        }

        if (bid.amount <= auction!.currentBid) {
          throw Exception('Bid must be higher than current bid');
        }

        final updatedBids = [...auction!.bids, bid];
        final updatedAuction = auction!.copyWith(
          currentBid: bid.amount,
          bids: updatedBids,
          updatedAt: DateTime.now(),
        );

        transaction.update(auctionRef, updatedAuction.toFirestore());
      });

      // Tell the seller someone bid on their auction (notifyUser never throws)
      if (auction != null && auction!.sellerUid != bid.bidderUid) {
        await _notificationService.notifyUser(
          userId: auction!.sellerUid,
          title: 'New Bid on Your Auction',
          message:
              '${bid.bidderName} bid RM${bid.amount.toStringAsFixed(2)} on "${auction!.title}"',
          type: NotificationType.auctionNewBid,
          data: {
            'auctionId': auctionId,
            'auctionTitle': auction!.title,
            'newHighestBid': bid.amount,
          },
        );
      }

      // Notify previous highest bidder if they were outbid
      if (auction != null && auction!.bids.isNotEmpty) {
        final previousHighestBid = auction!.bids.reduce(
          (a, b) => a.amount > b.amount ? a : b,
        );
        if (previousHighestBid.bidderUid != bid.bidderUid) {
          // The bid is already committed; a notification failure must not
          // make it look like the bid failed.
          try {
            await _notificationService.createAuctionOutbidNotification(
              auctionId: auctionId,
              bidderId: previousHighestBid.bidderUid,
              auctionTitle: auction!.title,
              newHighestBid: bid.amount,
            );
          } catch (e) {
            debugPrint('Outbid notification failed: $e');
          }
        }
      }
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

      late AuctionModel auction;

      await _firebaseService.firestore.runTransaction((transaction) async {
        final auctionDoc = await transaction.get(auctionRef);

        if (!auctionDoc.exists) {
          throw Exception('Auction not found');
        }

        auction = AuctionModel.fromFirestore(auctionDoc);

        if (auction.status != 'active') {
          throw Exception('Auction is not active');
        }

        // Update auction status
        transaction.update(auctionRef, {
          'status': 'ended',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Everything below runs once, after the transaction committed (the
      // transaction callback can be retried).
      final highestBid = auction.bids.isNotEmpty ? auction.highestBid : null;
      String? orderId;

      if (highestBid != null) {
        orderId = await _createOrderFromAuction(auction, highestBid);

        // notifyUser never throws, so a notification problem cannot make a
        // closed auction look like it failed to end.
        await _notificationService.notifyUser(
          userId: highestBid.bidderUid,
          title: 'Congratulations! You Won!',
          message:
              'You won the auction for "${auction.title}" with a bid of RM${highestBid.amount.toStringAsFixed(2)}',
          type: NotificationType.auctionWon,
          data: {
            'auctionId': auctionId,
            'auctionTitle': auction.title,
            'orderId': orderId,
          },
        );
      }

      // Everyone else who bid
      final otherBidders = auction.bids
          .map((b) => b.bidderUid)
          .where((uid) => uid != highestBid?.bidderUid)
          .toSet();
      for (final uid in otherBidders) {
        await _notificationService.notifyUser(
          userId: uid,
          title: 'Auction Ended',
          message: 'The auction for "${auction.title}" has ended',
          type: NotificationType.auctionEnded,
          data: {'auctionId': auctionId, 'auctionTitle': auction.title},
        );
      }

      // The seller
      await _notificationService.notifyUser(
        userId: auction.sellerUid,
        title: 'Your Auction Ended',
        message: highestBid != null
            ? '"${auction.title}" sold to ${highestBid.bidderName} for RM${highestBid.amount.toStringAsFixed(2)}'
            : '"${auction.title}" ended with no bids',
        type: NotificationType.auctionEnded,
        data: {
          'auctionId': auctionId,
          'auctionTitle': auction.title,
          'orderId': orderId,
          'asSeller': true,
          // Sold -> the new order is under Track Order; no bids -> Auction Items
          'sellerTab': highestBid != null ? 1 : 2,
        },
      );
    } catch (e) {
      throw Exception('Failed to end auction: $e');
    }
  }

  // Create order from auction for highest bidder
  Future<String> _createOrderFromAuction(
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

      final orderRef = await _firebaseService.firestore
          .collection('orders')
          .add(orderData);

      debugPrint(
        '✅ Order created for auction ${auction.id} - Winner: ${highestBid.bidderName}',
      );
      return orderRef.id;
    } catch (e) {
      debugPrint('❌ Error creating order from auction: $e');
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
  // Bids are an array of maps inside each auction, which Firestore cannot
  // query by bidderUid, so we stream recent auctions and filter in the app.
  Stream<List<AuctionModel>> getUserBidAuctionsStream(String bidderUid) {
    return _firebaseService.firestore
        .collection('auctions')
        .orderBy('endTime', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AuctionModel.fromFirestore)
              .where((a) => a.bids.any((b) => b.bidderUid == bidderUid))
              .toList(),
        );
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
          debugPrint('✅ Ended expired auction: ${doc.id}');
        } catch (e) {
          debugPrint('❌ Error ending expired auction ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking expired auctions: $e');
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
      debugPrint('❌ Error getting expired auction IDs: $e');
      return [];
    }
  }
}
