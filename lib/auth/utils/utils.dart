// =============================================================================
// 13. HELPERS
// =============================================================================

import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/auth/firebaseService.dart';
import 'package:digitaltv/auth/page/page.dart';
import 'package:digitaltv/auth/widget/widget.dart';
import 'package:flutter/material.dart';

const TextStyle inputStyle = TextStyle(color: T.textHi, fontSize: 14);

class CompanyCard extends StatelessWidget {
  final Company company;
  final FirebaseService svc;
  final VoidCallback onEdit;
  const CompanyCard({
    required this.company,
    required this.svc,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = company.isActive;
    return CardContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: T.primaryLo,
                borderRadius: T.r12,
                border: Border.all(color: T.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.business_rounded,
                  color: T.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name,
                      style: const TextStyle(
                          color: T.textHi,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(company.legalName,
                      style: const TextStyle(color: T.textMid, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(company.email,
                      style: const TextStyle(color: T.textLo, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: company.status),
            const SizedBox(width: 8),
            ActionBtn(
              icon: Icons.edit_outlined,
              color: T.primary,
              tooltip: 'Editar',
              onTap: onEdit,
            ),
            const SizedBox(width: 4),
            ActionBtn(
              icon: isActive ? Icons.block_rounded : Icons.lock_open_rounded,
              color: isActive ? T.warning : T.success,
              tooltip: isActive ? 'Desactivar' : 'Activar',
              onTap: () async => await svc.updateCompanyStatus(
                companyId: company.id,
                status: isActive ? 'suspended' : 'active',
              ),
            ),
            const SizedBox(width: 4),
            ActionBtn(
              icon: Icons.delete_outline_rounded,
              color: T.error,
              tooltip: 'Eliminar',
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: T.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: T.border),
        ),
        title:
            const Text('Eliminar empresa', style: TextStyle(color: T.textHi)),
        content: Text(
            '¿Desactivar "${company.name}"? Los usuarios no podrán iniciar sesión.',
            style: const TextStyle(color: T.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: T.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              await svc.deleteCompany(company.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: T.error, minimumSize: const Size(80, 36)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class NavItemData {
  final String route;
  final IconData icon;
  final String label;
  const NavItemData(
      {required this.route, required this.icon, required this.label});
}

class AppRoutesAuth {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const notifications2 = '/notifications2';
  static const roles = '/roles';
  static const dashboard = '/dashboard';
  static const users = '/users';
  static const panel = '/panel';
  static const companies = '/companies';
  static const superDashboard = '/super-dashboard';
  // ── rutas exclusivas superAdmin ──
  static const superUsers = '/super/users';
  static const superRoles = '/super/roles';
  static const superNotifications = '/super/notifications';
  static const superProfile = '/super/profile';
}

InputDecoration inputDeco({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: T.textMid),
      suffixIcon: suffix,
    );

Widget togglePassButton({
  required bool show,
  required VoidCallback onTap,
}) =>
    IconButton(
      icon: Icon(
        show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 18,
        color: T.textMid,
      ),
      onPressed: onTap,
    );

String formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'Ahora mismo';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';

  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
