import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/search_container_view_model.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/common/widgets/primary_header_container.dart';
import 'package:utmmart/core/common/widgets/search_container.dart';
import 'package:utmmart/features/shop/presentation/widgets/home_app_bar.dart';

class HomeHeaderSection extends StatelessWidget {
  final TextEditingController? searchController;

  const HomeHeaderSection({super.key, this.searchController});

  @override
  Widget build(BuildContext context) {
    final SearchContainerModel searchContainerModel = SearchContainerModel(
      icon: Iconsax.search_normal,
      title: TTexts.searchContainer,
      showBackground: true,
      showBorder: true,
      controller: searchController,
    );

    return PrimaryHeaderContainer(
      child: Column(
        children: [
          const HomeAppBar(),
          const SizedBox(height: TSizes.spaceBtwSections),
          SearchContainer(searchContainerModel: searchContainerModel),
          const SizedBox(height: TSizes.spaceBtwSections),
        ],
      ),
    );
  }
}
