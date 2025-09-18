import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/widgets/primary_header_container.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
// ...existing code...
import 'package:utmmart/features/personalization/presentation/view_models/settings_menu_tile_model.dart';
import 'package:utmmart/features/personalization/presentation/views/user_addresses_view.dart';
import 'package:utmmart/features/personalization/presentation/widgets/account_settings_section.dart';
import 'package:utmmart/features/personalization/presentation/widgets/app_settings_section.dart';
import 'package:utmmart/features/personalization/presentation/widgets/settings_view_header_section.dart';
import 'package:utmmart/features/shop/presentation/views/orders_view.dart';
import 'package:utmmart/features/shop/presentation/views/seller_dashboard_view.dart';
import 'package:utmmart/features/shop/presentation/views/cart_view.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:utmmart/features/notifications/presentation/views/notifications_view.dart';
import 'package:utmmart/features/notifications/presentation/widgets/notification_badge.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SettingsMenuTileModel> appSettingsTiles = [];
    final List<SettingsMenuTileModel> accountSettingsTiles = [
      // Vendor Dashboard - for all users since anyone can sell
      SettingsMenuTileModel(
        onTap: () async {
          final cachedUser = await sl<GetCachedUserUsecase>().call();
          final firebaseUser =
              sl<FirebaseAuthService>().currentUser ??
              fb_auth.FirebaseAuth.instance.currentUser;

          if (cachedUser != null || firebaseUser != null) {
            THelperFunctions.navigateToScreen(
              context,
              const SellerDashboardView(),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to access seller dashboard'),
              ),
            );
          }
        },
        title: "Seller Dashboard",
        subtitle: "Manage your products and sales",
        leading: Iconsax.shop,
      ),
      SettingsMenuTileModel(
        onTap: () {
          //navigateToScreen UserAddressesView
          THelperFunctions.navigateToScreen(context, const UserAddressesView());
        },
        title: "My Addresses",
        subtitle: "Set Shopping Delivery Address",
        leading: Iconsax.safe_home,
      ),
      SettingsMenuTileModel(
        onTap: () {
          THelperFunctions.navigateToScreen(context, const CartView());
        },
        title: "My Cart",
        subtitle: "Add, Remove Products And Move To Checkout",
        leading: Iconsax.shopping_cart,
      ),
      SettingsMenuTileModel(
        onTap: () {
          //navigateToScreen UserAddressesView
          THelperFunctions.navigateToScreen(context, const OrdersView());
        },
        title: "My Orders",
        subtitle: "In-Progress And Completed Orders",
        leading: Iconsax.bag,
      ),
      SettingsMenuTileModel(
        onTap: () {
          THelperFunctions.navigateToScreen(context, const NotificationsView());
        },
        title: "Notifications",
        subtitle: "Order updates, auction alerts, and more",
        leading: Iconsax.notification,
        trailing: const NotificationBadge(
          child: Icon(Iconsax.arrow_right_3, size: 16),
        ),
      ),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const PrimaryHeaderContainer(child: SettingsViewHeaderSection()),
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  AccountSettingsSection(
                    accountSettingsTiles: accountSettingsTiles,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  AppSettingsSection(appSettingsTiles: appSettingsTiles),
                  const SizedBox(height: TSizes.spaceBtwItems),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
