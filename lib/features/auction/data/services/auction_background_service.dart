import 'dart:async';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';

class AuctionBackgroundService {
  static final AuctionBackgroundService _instance =
      AuctionBackgroundService._internal();
  factory AuctionBackgroundService() => _instance;
  AuctionBackgroundService._internal();

  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  Timer? _timer;

  // Start the background service to check for expired auctions
  void startService() {
    // Check every 5 minutes for expired auctions
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkExpiredAuctions();
    });
  }

  // Stop the background service
  void stopService() {
    _timer?.cancel();
    _timer = null;
  }

  // Check and end expired auctions
  Future<void> _checkExpiredAuctions() async {
    try {
      await _auctionService.checkAndEndExpiredAuctions();
    } catch (e) {
      print('❌ Error in background auction check: $e');
    }
  }

  // Manual check for expired auctions (can be called from UI)
  Future<void> checkExpiredAuctions() async {
    await _checkExpiredAuctions();
  }
}
