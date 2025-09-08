import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/auth/data/models/firestore_user_model.dart';
import 'package:utmmart/features/auth/presentation/views/login/login_view.dart';
import 'package:utmmart/features/personalization/presentation/view_models/profile_entity_tile_model.dart';
import 'package:utmmart/features/personalization/presentation/widgets/personal_information_section.dart';
import 'package:utmmart/features/personalization/presentation/widgets/profile_information_section.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();
  FirestoreUserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final result = await _authService.getCurrentUserDocument();
    result.fold(
      (error) {
        THelperFunctions.showSnackBar(
          context: context,
          message: error,
          type: SnackBarType.error,
        );
        setState(() => _isLoading = false);
      },
      (user) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: CustomAppBar(
          appBarModel: AppBarModel(
            title: const Text("Profile"),
            hasArrowBack: true,
          ),
        ),
        body: const Center(child: Text("Failed to load user data")),
      );
    }

    final List<ProfileEntityTileModel> profileInformation = [
      ProfileEntityTileModel(
        title: "First Name",
        value: _currentUser!.firstName,
        onTap: () => _editField("firstName", _currentUser!.firstName),
      ),
      ProfileEntityTileModel(
        title: "Last Name",
        value: _currentUser!.lastName,
        onTap: () => _editField("lastName", _currentUser!.lastName),
      ),
      ProfileEntityTileModel(
        title: "Username",
        value: _currentUser!.username,
        onTap: null, // Username is derived from email, not editable
      ),
    ];

    final List<ProfileEntityTileModel> personalInformation = [
      ProfileEntityTileModel(
        title: "Email",
        value: _currentUser!.email,
        onTap: null, // Email is not editable after registration
      ),
      ProfileEntityTileModel(
        title: "Phone Number",
        value: _currentUser!.phoneNumber,
        onTap: () => _editField("phoneNumber", _currentUser!.phoneNumber),
      ),
      ProfileEntityTileModel(
        title: "Address",
        value: _currentUser!.address,
        onTap: () => _editField("address", _currentUser!.address),
      ),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: const Text("Profile"),
          hasArrowBack: true,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                ProfileInformationSection(
                  profileInformation: profileInformation,
                  profileImageUrl: _currentUser?.profileImageUrl,
                  onProfileUpdated: _loadUserData,
                ),
                const SpaceBetweenSectionsWithDivider(),
                PersonalInformationSection(
                  personalInformation: personalInformation,
                ),
                const SpaceBetweenSectionsWithDivider(),
                TextButton(
                  onPressed: () => _showDeleteAccountDialog(context),
                  child: const Text(
                    "Delete Account",
                    style: TextStyle(color: TColors.error),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 1.5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editField(String fieldName, String currentValue) async {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${_getFieldDisplayName(fieldName)}'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: _getFieldDisplayName(fieldName),
              border: const OutlineInputBorder(),
            ),
            maxLines: fieldName == 'address' ? 3 : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result != currentValue) {
      await _updateUserField(fieldName, result);
    }
  }

  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'firstName':
        return 'First Name';
      case 'lastName':
        return 'Last Name';
      case 'phoneNumber':
        return 'Phone Number';
      case 'address':
        return 'Address';
      default:
        return fieldName;
    }
  }

  Future<void> _updateUserField(String fieldName, String newValue) async {
    final result = await _authService.updateCurrentUserDocument({
      fieldName: newValue,
    });

    result.fold(
      (error) {
        THelperFunctions.showSnackBar(
          context: context,
          message: error,
          type: SnackBarType.error,
        );
      },
      (_) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Profile updated successfully',
          type: SnackBarType.success,
        );
        _loadUserData(); // Reload user data
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('This action will permanently:'),
              SizedBox(height: 4),
              Text('• Delete all your personal data'),
              Text('• Remove your account from our system'),
              Text('• Cancel any pending orders'),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone!',
                style: TextStyle(
                  color: TColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: TColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Deleting account..."),
            ],
          ),
        );
      },
    );

    try {
      final result = await _authService.deleteCurrentUserAccount();

      // Always hide loading indicator first
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      result.fold(
        (error) {
          THelperFunctions.showSnackBar(
            context: context,
            message: error,
            type: SnackBarType.error,
          );
        },
        (_) {
          // Show success message
          THelperFunctions.showSnackBar(
            context: context,
            message: 'Account deleted successfully. Redirecting to login...',
            type: SnackBarType.success,
          );

          // Wait a moment for the user to see the message
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              try {
                // Navigate to login screen and clear all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (Route<dynamic> route) => false,
                );
              } catch (navError) {
                print('Navigation error: $navError');
                // Fallback: just navigate to login without clearing routes
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                }
              }
            }
          });
        },
      );
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'An error occurred: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }
}

class SpaceBetweenSectionsWithDivider extends StatelessWidget {
  const SpaceBetweenSectionsWithDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: TSizes.spaceBtwItems / 1.5),
        Divider(),
        SizedBox(height: TSizes.spaceBtwItems / 1.5),
      ],
    );
  }
}
