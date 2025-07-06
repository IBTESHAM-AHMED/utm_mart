import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/device/device_utility.dart';
import 'package:utmmart/features/auth/presentation/logic/on_boarding/on_boarding_cubit.dart';

class OnBoardingSkipButton extends StatelessWidget {
  const OnBoardingSkipButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TDeviceUtils.getAppBarHeight(),
      right: TSizes.defaultSpace,
      child: TextButton(
        onPressed: context.read<OnBoardingCubit>().skipPage,
        child: const Text('Skip'),
      ),
    );
  }
}
