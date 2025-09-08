import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/widgets/primary_header_container.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auth/presentation/logic/get_cached_user/get_cached_user_cubit.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/features/personalization/presentation/view_models/settings_menu_tile_model.dart';
import 'package:utmmart/features/personalization/presentation/views/user_addresses_view.dart';
import 'package:utmmart/features/personalization/presentation/widgets/account_settings_section.dart';
import 'package:utmmart/features/personalization/presentation/widgets/app_settings_section.dart';
import 'package:utmmart/features/personalization/presentation/widgets/settings_view_header_section.dart';
import 'package:utmmart/features/shop/presentation/views/orders_view.dart';
import 'package:utmmart/features/shop/presentation/views/seller_dashboard_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SettingsMenuTileModel> appSettingsTiles = [];
    final List<SettingsMenuTileModel> accountSettingsTiles = [
      // Vendor Dashboard - for all users since anyone can sell
      SettingsMenuTileModel(
        onTap: () {
          // Get current user and navigate to vendor dashboard
          final userState = context.read<CachedUserCubit>().state;
          if (userState.status == CachedUserStatus.success &&
              userState.userData != null) {
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
        onTap: () {},
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
