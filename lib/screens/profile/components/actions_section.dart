import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../utils/extensions.dart';
import '../../../components/delete_account_modal.dart';
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
              onTap: () => _handleDeleteAccount(context),
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

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const DeleteAccountModal();
      },
    );

    if (confirmDelete == true && context.mounted) {
      // Mostrar el modal de progreso mejorado
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const DeletingAccountModal();
        },
      );

      try {
        // Obtener ID del usuario actual
        final userId = await DashboardService.getCurrentUserId();

        if (userId == null || userId.isEmpty) {
          throw Exception('No se pudo obtener el ID del usuario');
        }

        // Convertir userId string a int
        final userIdInt = int.tryParse(userId);
        if (userIdInt == null) {
          throw Exception('ID de usuario inválido');
        }

        // Llamar al servicio de eliminación
        final success = await ProfileService.deleteAccount(userId: userIdInt);

        if (context.mounted) {
          Navigator.of(context).pop(); // Cerrar dialog de progreso
        }

        if (success) {
          if (context.mounted) {
            // Mostrar mensaje de confirmación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr.translate('account_deleted_successfully') ??
                      'Cuenta eliminada exitosamente',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );

            // Limpiar sesión y redirigir al onboarding
            await AuthService.signOut(context);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              (route) => false,
            );
          }
        } else {
          throw Exception('Error al eliminar la cuenta');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Cerrar dialog de progreso

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${context.tr.translate('delete_account_error') ?? 'Error al eliminar cuenta'}: $e',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
