import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/section_heading_view_model.dart';
import 'package:utmmart/core/common/widgets/section_heading.dart';
import 'package:utmmart/features/personalization/presentation/view_models/settings_menu_tile_model.dart';
import 'package:utmmart/features/personalization/presentation/widgets/settings_menu_tile_list.dart';

class AccountSettingsSection extends StatelessWidget {
  const AccountSettingsSection({
    super.key,
    required this.accountSettingsTiles,
  });
  final List<SettingsMenuTileModel> accountSettingsTiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeading(
            sectionHeadingModel: SectionHeadingModel(
          title: "Account Settings",
          showActionButton: false,
        )),
        SettingsMenuTileList(settingsMenuTiles: accountSettingsTiles),
      ],
    );
  }
}
