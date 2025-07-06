import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/view_models/cart_counter_icon_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/common/widgets/cart_counter_icon.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/shop/presentation/views/cart_view.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      appBarModel: AppBarModel(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TTexts.homeAppbarTitle,
              style: Theme.of(context).textTheme.labelMedium!.apply(
                    color: TColors.grey,
                  ),
            ),
            Text(
              TTexts.homeAppbarSubTitle,
              style: Theme.of(context).textTheme.headlineSmall!.apply(
                    color: TColors.white,
                  ),
            ),
          ],
        ),
        actions: [
          CartCounterIcon(
            cartCounterIconModel: CartCounterIconModel(
              color: TColors.white,
              onPressed: () {
                THelperFunctions.navigateToScreen(context, const CartView());
              },
            ),
          ),
        ],
      ),
    );
  }
}
