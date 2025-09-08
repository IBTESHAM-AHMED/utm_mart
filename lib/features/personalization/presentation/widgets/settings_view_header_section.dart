import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/image_strings.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/auth/data/models/firestore_user_model.dart';
import 'package:utmmart/features/personalization/presentation/view_models/user_profile_tile_model.dart';
import 'package:utmmart/features/personalization/presentation/views/profile_view.dart';
import 'package:utmmart/features/personalization/presentation/widgets/user_profile_tile.dart';

class SettingsViewHeaderSection extends StatefulWidget {
  const SettingsViewHeaderSection({super.key});

  @override
  State<SettingsViewHeaderSection> createState() =>
      _SettingsViewHeaderSectionState();
}

class _SettingsViewHeaderSectionState extends State<SettingsViewHeaderSection> {
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
    return Column(
      children: [
        CustomAppBar(
          appBarModel: AppBarModel(
            title: Text(
              TTexts.account,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium!.apply(color: TColors.white),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        UserProfileTile(
          userProfileTileModel: UserProfileTileModel(
            title: _currentUser?.fullName ?? "Loading...",
            subtitle: _currentUser?.email ?? "Loading...",
            onTap: () =>
                THelperFunctions.navigateToScreen(context, const ProfileView()),
            trailing: Iconsax.edit,
            leading: _currentUser?.profileImageUrl.isNotEmpty == true
                ? _currentUser!.profileImageUrl
                : TImages.user,
            isNetworkImage: _currentUser?.profileImageUrl.isNotEmpty == true,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwSections * 1.2),
      ],
    );
  }
}
