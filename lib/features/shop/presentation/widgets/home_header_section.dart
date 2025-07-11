import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/search_container_view_model.dart';
import 'package:utmmart/core/common/view_models/section_heading_view_model.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/common/widgets/primary_header_container.dart';
import 'package:utmmart/core/common/widgets/search_container.dart';
import 'package:utmmart/core/common/widgets/section_heading.dart';
import 'package:utmmart/features/shop/presentation/widgets/home_app_bar.dart';
import 'package:utmmart/features/shop/presentation/widgets/home_categories.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final SectionHeadingModel sectionHeadingModel = SectionHeadingModel(
      showActionButton: false,
      title: TTexts.popularCategories,
      textColor: TColors.white,
    );
    final SearchContainerModel searchContainerModel = SearchContainerModel(
      icon: Iconsax.search_normal,
      title: TTexts.searchContainer,
      showBackground: true,
      showBorder: true,
    );

    return PrimaryHeaderContainer(
      child: Column(
        children: [
          const HomeAppBar(),
          const SizedBox(height: TSizes.spaceBtwSections),
          SearchContainer(searchContainerModel: searchContainerModel),
          const SizedBox(
            height: TSizes.spaceBtwSections,
          ),
          Padding(
              padding: const EdgeInsets.only(left: TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    sectionHeadingModel: sectionHeadingModel,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  const HomeCategories(),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              ))
        ],
      ),
    );
  }
}
