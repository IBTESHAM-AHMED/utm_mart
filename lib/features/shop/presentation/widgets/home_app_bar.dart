import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/view_models/cart_counter_icon_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/common/widgets/cart_counter_icon.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/auth/data/models/firestore_user_model.dart';
import 'package:utmmart/features/shop/presentation/views/cart_view.dart';

class HomeAppBar extends StatefulWidget {
  const HomeAppBar({super.key});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();
  FirestoreUserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final result = await _authService.getCurrentUserDocument();
    result.fold(
      (error) {
        // Handle error silently or show default data
        print('Error loading user data: $error');
      },
      (user) {
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      appBarModel: AppBarModel(
        title: Row(
          children: [
            // Profile Image
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TColors.white, width: 2),
              ),
              child: ClipOval(
                child: _currentUser?.profileImageUrl.isNotEmpty == true
                    ? Image.network(
                        _currentUser!.profileImageUrl,
                        fit: BoxFit.cover,
                        width: 45,
                        height: 45,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: TColors.grey.withOpacity(0.3),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TColors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: TColors.grey.withOpacity(0.3),
                            child: const Icon(
                              Icons.person,
                              color: TColors.white,
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: TColors.grey.withOpacity(0.3),
                        child: const Icon(
                          Icons.person,
                          color: TColors.white,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TTexts.homeAppbarTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium!.apply(color: TColors.grey),
                  ),
                  Text(
                    _currentUser?.fullName ?? "Loading...",
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall!.apply(color: TColors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CartCounterIcon(
            cartCounterIconModel: CartCounterIconModel(
              color: TColors.white,
              onPressed: () {
                THelperFunctions.navigateToScreen(context, const CartView());
              },
            ),
          ),
        ],
      ),
    );
  }
}
