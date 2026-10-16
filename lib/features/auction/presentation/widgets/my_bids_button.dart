import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/features/auction/presentation/views/my_bids_view.dart';

/// App bar button that opens My Bids, badged with the number of live
/// auctions the user has bid on.
class MyBidsButton extends StatefulWidget {
  const MyBidsButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  State<MyBidsButton> createState() => _MyBidsButtonState();
}

class _MyBidsButtonState extends State<MyBidsButton> {
  Stream<List<AuctionModel>>? _stream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _stream = sl<AuctionFirestoreService>().getUserBidAuctionsStream(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        final live = snapshot.data?.where((a) => !a.hasEnded).length ?? 0;
        return Stack(
          children: [
            IconButton(
              tooltip: 'My Bids',
              onPressed: () => THelperFunctions.navigateToScreen(
                context,
                const MyBidsView(),
              ),
              icon: Icon(
                Iconsax.timer_1,
                color: widget.iconColor ?? TColors.primary,
              ),
            ),
            if (live > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    live > 99 ? '99+' : '$live',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
