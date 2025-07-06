import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auth/presentation/views/password_configuration/reset_password_view.dart';

class ForgetPasswordFormSection extends StatelessWidget {
  const ForgetPasswordFormSection({super.key});
//ForgetPasswordFormSection >> forget_password_form_section.dart
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                labelText: TTexts.email),
          ),
          const SizedBox(
            height: TSizes.spaceBtwInputFields,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  THelperFunctions.navigateReplacementToScreen(
                      context, const ResetPasswordView());
                },
                child: const Text(TTexts.submit)),
          ),
        ],
      ),
    );
  }
}
