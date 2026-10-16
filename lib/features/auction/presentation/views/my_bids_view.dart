import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/features/auction/presentation/views/auction_detail_view.dart';
import 'package:utmmart/features/shop/presentation/views/order_detail_view.dart';

/// Tracks the auctions the signed-in user has bid on: live ones with a
/// Winning / Outbid status, and finished ones as Won / Lost.
class MyBidsView extends StatefulWidget {
  const MyBidsView({super.key});

  @override
  State<MyBidsView> createState() => _MyBidsViewState();
}

class _MyBidsViewState extends State<MyBidsView> {
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Stream<List<AuctionModel>>? _stream;

  @override
  void initState() {
    super.initState();
    if (_uid != null) {
      _stream = _auctionService.getUserBidAuctionsStream(_uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          appBarModel: AppBarModel(
            hasArrowBack: true,
            title: const Text('My Bids'),
          ),
        ),
        body: _stream == null
            ? const Center(child: Text('Please log in to see your bids'))
            : StreamBuilder<List<AuctionModel>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(TSizes.defaultSpace),
                        child: Text('Could not load bids: ${snapshot.error}'),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all = snapshot.data!;
                  final active = all.where((a) => !a.hasEnded).toList()
                    ..sort((a, b) => a.endTime.compareTo(b.endTime));
                  final ended = all.where((a) => a.hasEnded).toList();
                  return Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: 'Active (${active.length})'),
                          Tab(text: 'Ended (${ended.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _BidList(
                              auctions: active,
                              uid: _uid!,
                              emptyText: 'You have no live bids',
                            ),
                            _BidList(
                              auctions: ended,
                              uid: _uid,
                              emptyText: 'No finished auctions yet',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _BidList extends StatelessWidget {
  const _BidList({
    required this.auctions,
    required this.uid,
    required this.emptyText,
  });

  final List<AuctionModel> auctions;
  final String uid;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (auctions.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: THelperFunctions.mutedTextColor(context)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: auctions.length,
      separatorBuilder: (_, _) => const SizedBox(height: TSizes.spaceBtwItems),
      itemBuilder: (_, i) => _BidCard(auction: auctions[i], uid: uid),
    );
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard({required this.auction, required this.uid});

  final AuctionModel auction;
  final String uid;

  double get _myTopBid => auction.bids
      .where((b) => b.bidderUid == uid)
      .map((b) => b.amount)
      .reduce((a, b) => a > b ? a : b);

  bool get _isHighest => auction.highestBid?.bidderUid == uid;

  String _timeLeft() {
    final d = auction.timeRemaining;
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s left';
    return '${d.inSeconds}s left';
  }

  @override
  Widget build(BuildContext context) {
    final muted = THelperFunctions.mutedTextColor(context);
    final ended = auction.hasEnded;
    final label = ended
        ? (_isHighest ? 'Won' : 'Lost')
        : (_isHighest ? 'Winning' : 'Outbid');
    final color = _isHighest ? TColors.success : TColors.error;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => THelperFunctions.navigateToScreen(
          context,
          AuctionDetailView(auction: auction),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      auction.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 64,
                        height: 64,
                        color: muted.withValues(alpha: 0.2),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ended ? 'Ended' : _timeLeft(),
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your bid: RM${_myTopBid.toStringAsFixed(2)}',
                    style: TextStyle(color: muted),
                  ),
                  Text(
                    ended
                        ? 'Final: RM${auction.currentBid.toStringAsFixed(2)}'
                        : 'Current: RM${auction.currentBid.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (ended && _isHighest) ...[
                const SizedBox(height: TSizes.spaceBtwItems),
                SizedBox(
                  width: double.infinity,
                  child: _ViewOrderButton(auction: auction, uid: uid),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the order created for a won auction. If the auction has not been
/// closed yet (closing is what creates the order), closes it first.
class _ViewOrderButton extends StatefulWidget {
  const _ViewOrderButton({required this.auction, required this.uid});

  final AuctionModel auction;
  final String uid;

  @override
  State<_ViewOrderButton> createState() => _ViewOrderButtonState();
}

class _ViewOrderButtonState extends State<_ViewOrderButton> {
  bool _loading = false;

  Future<String?> _findOrderId() async {
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: widget.uid)
        .where('auctionId', isEqualTo: widget.auction.id)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  Future<void> _open() async {
    setState(() => _loading = true);
    String? orderId;
    try {
      orderId = await _findOrderId();
      if (orderId == null && widget.auction.status == 'active') {
        await sl<AuctionFirestoreService>().endAuction(widget.auction.id!);
        orderId = await _findOrderId();
      }
    } catch (e) {
      debugPrint('View auction order failed: $e');
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order not ready yet, try again shortly')),
      );
      return;
    }
    THelperFunctions.navigateToScreen(
      context,
      OrderDetailView(orderId: orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _loading ? null : _open,
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('View my order'),
    );
  }
}
