import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/search_container_view_model.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/device/device_utility.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';

class SearchContainer extends StatelessWidget {
  const SearchContainer({super.key, required this.searchContainerModel});
  final SearchContainerModel searchContainerModel;
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: searchContainerModel.padding,
      child: Container(
        width: TDeviceUtils.getScreenWidth(context),
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: searchContainerModel.showBackground
              ? dark
                    ? TColors.dark
                    : TColors.light
              : Colors.transparent,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          border: searchContainerModel.showBorder
              ? Border.all(color: TColors.grey)
              : null,
        ),
        child: Row(
          children: [
            Icon(searchContainerModel.icon, color: TColors.darkGrey),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: searchContainerModel.controller != null
                  ? TextField(
                      controller: searchContainerModel.controller,
                      decoration: InputDecoration(
                        hintText: searchContainerModel.title,
                        border: InputBorder.none,
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : GestureDetector(
                      onTap: searchContainerModel.onPressed,
                      child: Text(
                        searchContainerModel.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

//search container model
