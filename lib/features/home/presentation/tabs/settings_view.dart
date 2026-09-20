import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';

/// Tab "Ajustes": edición de perfil (próximo flujo), preferencias de
/// notificaciones y cierre de sesión. El logout vive aquí, fuera del AppBar.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Próximamente'),
          backgroundColor: AppColors.carbon,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: AppColors.carbon,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          '¿Seguro que quieres salir de tu cuenta?',
          style: TextStyle(
            color: AppColors.grayMain,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.grayMain,
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajustes',
              style: TextStyle(
                color: AppColors.carbon,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tu cuenta y tus preferencias.',
              style: TextStyle(
                color: AppColors.grayMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.subtleBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Editar perfil y métricas',
                    onTap: () => _comingSoon(context),
                  ),
                  const Divider(color: AppColors.subtleBorder, height: 1),
                  _SettingsTile(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Nivel de actividad',
                    onTap: () => _comingSoon(context),
                  ),
                  const Divider(color: AppColors.subtleBorder, height: 1),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificaciones',
                    onTap: () => _comingSoon(context),
                  ),
                  const Divider(color: AppColors.subtleBorder, height: 1),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: 'Idioma',
                    onTap: () => _comingSoon(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.subtleBorder),
              ),
              child: _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Cerrar sesión',
                destructive: true,
                showChevron: false,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.carbon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.grayMain.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}