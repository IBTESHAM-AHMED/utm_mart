import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/circular_container_view_model.dart';
import 'package:utmmart/core/common/widgets/circular_container.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';

class SaleTag extends StatelessWidget {
  const SaleTag({
    super.key,
    required this.discountPercentage,
  });
  final double discountPercentage;
  @override
  Widget build(BuildContext context) {
    return CircularContainer(
        circularContainerModel: CircularContainerModel(
      padding: const EdgeInsets.symmetric(
          horizontal: TSizes.sm, vertical: TSizes.xs),
      borderRadius: TSizes.sm,
      color: TColors.secondary.withValues(alpha: .8),
      child: Text(
        '$discountPercentage%',
        style:
            Theme.of(context).textTheme.labelLarge!.apply(color: TColors.black),
      ),
    ));
  }
}
