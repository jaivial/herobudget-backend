import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../utils/extensions.dart';
import '../edit_profile_screen.dart';

class UserProfileSection extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onProfileUpdated;

  const UserProfileSection({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              backgroundImage: _getProfileImage(),
              child:
                  user?.displayImage == null && user?.picture == null
                      ? Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      : null,
            ),

            const SizedBox(height: 16),

            // User name
            Text(
              user?.name ?? context.tr.translate('demo_user'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // User email
            Text(
              user?.email ?? 'email@example.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // Verification status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  user?.verifiedEmail == true
                      ? Icons.verified_user
                      : Icons.warning,
                  color:
                      user?.verifiedEmail == true
                          ? Colors.green
                          : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user?.verifiedEmail == true
                      ? context.tr.translate('email_verified')
                      : context.tr.translate('email_not_verified'),
                  style: TextStyle(
                    color:
                        user?.verifiedEmail == true
                            ? Colors.green
                            : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Edit profile button
            ElevatedButton.icon(
              onPressed: () {
                _navigateToEditProfile(context);
              },
              icon: const Icon(Icons.edit),
              label: Text(
                context.tr.translate('edit_profile'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (user == null) {
      return null;
    }
    return user!.getProfileImage();
  }

  Future<void> _navigateToEditProfile(BuildContext context) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.translate('error_loading_user_data') ??
                'Error: No se pudo cargar la información del usuario',
          ),
        ),
      );
      return;
    }

    if (context.mounted) {
      final updatedUser = await Navigator.of(context).push<UserModel>(
        MaterialPageRoute(builder: (context) => EditProfileScreen(user: user!)),
      );

      if (updatedUser != null) {
        onProfileUpdated();
      }
    }
  }
}
