import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/view_models/circular_icon_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/common/widgets/circular_icon.dart';
import 'package:utmmart/core/common/widgets/curved_widget.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/shop/presentation/widgets/other_same_products_list.dart';
import 'package:utmmart/features/shop/presentation/widgets/selected_product_image.dart';

class ProductImageSlider extends StatelessWidget {
  const ProductImageSlider({
    super.key,
  });

//ProductImageSlider >> product_image_slider.dart
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return CurvedWidget(
      child: Container(
        decoration: BoxDecoration(
          color: dark ? TColors.darkGrey : TColors.light,
        ),
        child: Stack(
          children: [
            const SelectedProductImage(),
            const OtherSameProductsList(),
            CustomAppBar(
                appBarModel: AppBarModel(hasArrowBack: true, actions: [
              CircularIcon(
                circularIconModel:
                    CircularIconModel(icon: Iconsax.heart5, color: Colors.red),
              ),
            ]))
          ],
        ),
      ),
    );
  }
}
