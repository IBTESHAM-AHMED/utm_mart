import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/view_models/brand_card_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/common/widgets/brand_card.dart';
import 'package:utmmart/core/utils/constants/image_strings.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/features/shop/presentation/widgets/sortable_products.dart';

class BrandProductsView extends StatelessWidget {
  const BrandProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(title: const Text("Nike"), hasArrowBack: true),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              BrandCard(
                  brandCardModel: BrandCardModel(
                      productCount: 5,
                      showBorder: true,
                      brandName: "Nike",
                      image: TImages.nikeLogo)),
              const SizedBox(
                height: TSizes.spaceBtwSections,
              ),
              const SortableProducts(),
            ],
          ),
        )),
      ),
    );
  }
}
