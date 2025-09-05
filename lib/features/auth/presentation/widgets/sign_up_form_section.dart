import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/constants/text_strings.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/utils/validators/validation.dart';
import 'package:utmmart/features/auth/domain/usecases/firebase_register_usecase.dart';
import 'package:utmmart/features/auth/presentation/logic/register/register_cubit.dart';
import 'package:utmmart/features/auth/presentation/logic/register/register_state.dart';
import 'package:utmmart/features/auth/presentation/views/login/login_view.dart';

import 'terms_and_privacy_agreement.dart';

class SignUpFormSection extends StatefulWidget {
  const SignUpFormSection({super.key});

  @override
  State<SignUpFormSection> createState() => _SignUpFormSectionState();
}

class _SignUpFormSectionState extends State<SignUpFormSection> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegistration() {
    if (_formKey.currentState!.validate()) {
      final params = FirebaseRegisterParams(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );

      context.read<RegisterCubit>().register(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state.status == RegisterStatus.success) {
          THelperFunctions.showSnackBar(
            context: context,
            message: state.message,
            type: SnackBarType.success,
          );

          THelperFunctions.navigateReplacementToScreen(context, LoginView());
        } else if (state.status == RegisterStatus.failure) {
          THelperFunctions.showSnackBar(
            context: context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              validator: (value) {
                return TValidator.validateEmail(value);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct),
                labelText: TTexts.email,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextFormField(
              keyboardType: TextInputType.visiblePassword,
              controller: _passwordController,
              validator: (value) => TValidator.validatePassword(value),
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.password_check),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                labelText: TTexts.password,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextFormField(
              keyboardType: TextInputType.visiblePassword,
              controller: _confirmPasswordController,
              validator: (value) => TValidator.validateConfirmPassword(
                value,
                _passwordController,
              ),
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.password_check),
                labelText: 'Confirm Password',
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            const TermsAndPrivacyAgreement(),
            const SizedBox(height: TSizes.spaceBtwSections),
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<RegisterCubit, RegisterState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.status == RegisterStatus.loading
                        ? null
                        : () {
                            THelperFunctions.hideKeyboard();
                            _handleRegistration();
                          },
                    child: state.status == RegisterStatus.loading
                        ? const Text(TTexts.loading)
                        : const Text(TTexts.createAccount),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
