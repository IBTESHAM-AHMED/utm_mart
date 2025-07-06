import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/circular_container_view_model.dart';
import 'package:utmmart/core/common/widgets/circular_container.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';

class CouponCode extends StatelessWidget {
  const CouponCode({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return CircularContainer(
      circularContainerModel: CircularContainerModel(
          padding: const EdgeInsets.fromLTRB(
              TSizes.md, TSizes.sm, TSizes.sm, TSizes.sm),
          showBorder: true,
          color: dark ? TColors.dark : TColors.white,
          child: Row(
            children: [
              Flexible(
                child: TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Have a promo code? Enter here",
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      border: InputBorder.none),
                ),
              ),
              SizedBox(
                width: 80,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(TSizes.md),
                      foregroundColor: dark
                          ? TColors.white.withValues(alpha: .5)
                          : TColors.dark.withValues(alpha: .5),
                      backgroundColor: Colors.grey.withValues(alpha: .2),
                      side:
                          BorderSide(color: Colors.grey.withValues(alpha: .1)),
                    ),
                    onPressed: () {},
                    child: const Text("Apply")),
              )
            ],
          )),
    );
  }
}
