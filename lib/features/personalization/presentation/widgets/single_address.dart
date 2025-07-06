import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/circular_container_view_model.dart';
import 'package:utmmart/core/common/widgets/circular_container.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/personalization/presentation/view_models/single_address_model.dart';

class SingleAddress extends StatelessWidget {
  const SingleAddress({super.key, required this.singleAddressModel});
  final SingleAddressModel singleAddressModel;
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return CircularContainer(
      circularContainerModel: CircularContainerModel(
          padding: const EdgeInsets.all(TSizes.md),
          width: double.infinity,
          showBorder: true,
          color: singleAddressModel.isSelected
              ? TColors.primary.withValues(alpha: .5)
              : Colors.transparent,
          borderColor: singleAddressModel.isSelected
              ? Colors.transparent
              : dark
                  ? TColors.darkerGrey
                  : TColors.grey,
          margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
          child: Stack(
            children: [
              Positioned(
                right: 5,
                top: 0,
                child: Icon(
                  singleAddressModel.isSelected ? Iconsax.tick_circle5 : null,
                  color: singleAddressModel.isSelected
                      ? dark
                          ? TColors.light
                          : TColors.dark //.withValues(alpha:.6)
                      : null,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    singleAddressModel.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: TSizes.sm / 2,
                  ),
                  Text(
                    singleAddressModel.phoneNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: TSizes.sm / 2,
                  ),
                  Text(
                    singleAddressModel.address,
                    softWrap: true,
                  ),
                ],
              )
            ],
          )),
    );
  }
}
