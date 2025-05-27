import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../utils/extensions.dart';
import '../../onboarding/onboarding_screen.dart';

class ActionsSection extends StatelessWidget {
  const ActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.translate('actions'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Logout button
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.tr.translate('logout'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _handleLogout(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Divider(),

            // Delete account button
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.tr.translate('delete_account'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr.translate('delete_account_coming_soon'),
                    ),
                  ),
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr.translate('logout')),
          content: Text(
            context.tr.translate('logout_confirmation') ??
                '¿Estás seguro que deseas cerrar sesión?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.tr.translate('cancel')),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(context.tr.translate('logout')),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true && context.mounted) {
      try {
        await AuthService.signOut(context);
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.tr.translate('logout_error')}: $e'),
            ),
          );
        }
      }
    }
  }
}
