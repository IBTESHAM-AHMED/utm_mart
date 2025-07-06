import 'package:flutter/material.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/image_strings.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';

class SignInMethodsSection extends StatelessWidget {
  const SignInMethodsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        decoration: BoxDecoration(
            border: Border.all(color: TColors.grey),
            borderRadius: BorderRadius.circular(100)),
        child: IconButton(
          onPressed: () {},
          icon: const Image(
            height: TSizes.iconMd,
            width: TSizes.iconMd,
            image: AssetImage(TImages.google),
          ),
        ),
      ),
      const SizedBox(
        width: TSizes.spaceBtwItems,
      ),
      Container(
        decoration: BoxDecoration(
            border: Border.all(color: TColors.grey),
            borderRadius: BorderRadius.circular(100)),
        child: IconButton(
          onPressed: () {},
          icon: const Image(
            height: TSizes.iconMd,
            width: TSizes.iconMd,
            image: AssetImage(TImages.facebook),
          ),
        ),
      ),
    ]);
  }
}
