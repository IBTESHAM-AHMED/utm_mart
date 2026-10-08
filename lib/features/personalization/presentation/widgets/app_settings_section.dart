import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/section_heading_view_model.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/domain/usecases/logout_usecase.dart';
import 'package:utmmart/core/common/widgets/section_heading.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auth/presentation/views/login/login_view.dart';
import 'package:utmmart/features/personalization/presentation/view_models/settings_menu_tile_model.dart';
import 'package:utmmart/features/personalization/presentation/widgets/settings_menu_tile_list.dart';

class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({
    super.key,
    required this.appSettingsTiles,
  });
  final List<SettingsMenuTileModel> appSettingsTiles;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeading(
          sectionHeadingModel: SectionHeadingModel(
            title: "App Settings",
            showActionButton: false,
          ),
        ),
        SettingsMenuTileList(settingsMenuTiles: appSettingsTiles),
        const SizedBox(
          height: TSizes.spaceBtwSections,
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              try {
                await sl<LogoutUsecase>().call();
              } catch (e) {
                debugPrint('Logout failed: $e');
              }
              if (!context.mounted) return;
              THelperFunctions.navigateReplacementToScreen(
                  context, const LoginView());
            },
            child: const Text("Logout"),
          ),
        ),
      ],
    );
  }
}
