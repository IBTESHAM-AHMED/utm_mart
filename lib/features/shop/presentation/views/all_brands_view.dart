import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/view_models/brand_card_view_model.dart';
import 'package:utmmart/core/common/view_models/grid_layout_view_model.dart';
import 'package:utmmart/core/common/view_models/section_heading_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/common/widgets/brand_card.dart';
import 'package:utmmart/core/common/widgets/section_heading.dart';
import 'package:utmmart/core/utils/constants/image_strings.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auth/presentation/widgets/grid_layout.dart';
import 'package:utmmart/features/shop/presentation/views/brand_products_view.dart';

class AllBrandsView extends StatelessWidget {
  const AllBrandsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel:
            AppBarModel(title: const Text("All Brands"), hasArrowBack: true),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              SectionHeading(
                sectionHeadingModel: SectionHeadingModel(
                  title: "All Brands",
                  showActionButton: false,
                ),
              ),
              const SizedBox(
                height: TSizes.spaceBtwItems,
              ),
              GridLayout(
                  gridLayoutModel: GridLayoutModel(
                itemCount: 10,
                mainAxisExtent: 80,
                itemBuilder: (context, index) {
                  return BrandCard(
                    brandCardModel: BrandCardModel(
                      onTap: () {
                        THelperFunctions.navigateToScreen(
                          context,
                          const BrandProductsView(),
                        );
                      },
                      showBorder: true,
                      productCount: TTexts.brandTitles.length,
                      brandName: TTexts.brandTitles[index],
                      image: TImages.brandIcons[index],
                    ),
                  );
                },
              )),
            ],
          ),
        )),
      ),
    );
  }
}
