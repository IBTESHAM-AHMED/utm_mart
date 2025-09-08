import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/rounded_image_view_model.dart';
import 'package:utmmart/core/common/view_models/section_heading_view_model.dart';
import 'package:utmmart/core/common/widgets/rounded_image.dart';
import 'package:utmmart/core/common/widgets/section_heading.dart';
import 'package:utmmart/core/utils/constants/image_strings.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/features/personalization/presentation/view_models/profile_entity_tile_model.dart';
import 'package:utmmart/features/personalization/presentation/views/profile_view.dart';
import 'package:utmmart/features/personalization/presentation/views/change_profile_picture_view.dart';
import 'package:utmmart/features/personalization/presentation/widgets/profile_entity_tile_list.dart';

class ProfileInformationSection extends StatelessWidget {
  const ProfileInformationSection({
    super.key,
    required this.profileInformation,
    this.profileImageUrl,
    this.onProfileUpdated,
  });
  final List<ProfileEntityTileModel> profileInformation;
  final String? profileImageUrl;
  final VoidCallback? onProfileUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              RoundedImage(
                roundedImageModel: RoundedImageModel(
                  image: profileImageUrl?.isNotEmpty == true
                      ? profileImageUrl!
                      : TImages.user,
                  width: 80,
                  height: 80,
                  isNetworkImage: profileImageUrl?.isNotEmpty == true,
                  applyImageRadius: true,
                  borderRadius: 40, // Make it circular
                  fit: BoxFit.cover,
                  onTap: () => _navigateToChangeProfilePicture(context),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToChangeProfilePicture(context),
                child: const Text("Change Profile Picture"),
              ),
            ],
          ),
        ),
        const SpaceBetweenSectionsWithDivider(),
        SectionHeading(
          sectionHeadingModel: SectionHeadingModel(
            title: "Profile Information",
            showActionButton: false,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),
        ProfileEntityTileList(profileEntityTileModelList: profileInformation),
      ],
    );
  }

  Future<void> _navigateToChangeProfilePicture(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ChangeProfilePictureView()),
    );

    // If profile was updated successfully, refresh the parent widget
    if (result == true && onProfileUpdated != null) {
      onProfileUpdated!();
    }
  }
}
