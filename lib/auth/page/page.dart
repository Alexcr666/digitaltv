import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/auth/auth.dart' as current2;
import 'package:digitaltv/auth/firebaseService.dart';
import 'package:digitaltv/auth/page/login.dart';
import 'package:digitaltv/auth/utils/utils.dart';
import 'package:digitaltv/auth/widget/widget.dart';
import 'package:digitaltv/chatbot/chatbot.dart';
import 'package:digitaltv/config/app_config.dart';
import 'package:digitaltv/logo.dart';
import 'package:digitaltv/provider/app_providers.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:digitaltv/route/route.dart';
import 'package:digitaltv/ui/panel/device_portal_screen.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:digitaltv/ui/panel/panel/page/pageDevice.dart';
import 'package:digitaltv/ui/panel/panel2.dart';
import 'package:digitaltv/ui/panel/panel3.dart';
import 'package:digitaltv/ui/panel/playlist2.dart';
import 'package:digitaltv/ui/dashboard.dart';
import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/notification/notification.dart';
import 'package:digitaltv/ui/programming/programing.dart';
import 'package:digitaltv/utils/permission_label.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CompanyDetailPage extends ConsumerWidget {
  final String companyId;
  const CompanyDetailPage({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesProvider);
    final allUsers = ref.watch(allUsersProvider);

    final company =
        companies.valueOrNull?.where((c) => c.id == companyId).firstOrNull;
    final companyUsers =
        allUsers.valueOrNull?.where((u) => u.companyId == companyId).toList() ??
            [];

    if (company == null) {
      return const Center(child: CircularProgressIndicator(color: T.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutesAuth.superDashboard),
                child: const Icon(Icons.arrow_back_rounded,
                    color: T.textMid, size: 20),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: T.primaryLo,
                  borderRadius: T.r12,
                  border: Border.all(color: T.primary.withOpacity(0.3)),
                ),
                child: const Icon(Icons.business_rounded,
                    color: T.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name,
                        style: const TextStyle(
                            color: T.textHi,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    Text(company.email,
                        style: const TextStyle(color: T.textMid, fontSize: 13)),
                  ],
                ),
              ),
              StatusBadge(status: company.status),
            ],
          ),
          const SizedBox(height: 20),

          // ── Info de empresa ──
          CardContainer(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información de la empresa',
                      style: TextStyle(
                          color: T.textHi,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  InfoRow(label: 'Razón social', value: company.legalName),
                  InfoRow(label: 'Email', value: company.email),
                  InfoRow(
                      label: 'Teléfono',
                      value: company.phone.isEmpty ? '—' : company.phone),
                  InfoRow(
                      label: 'Dirección',
                      value: company.address.isEmpty ? '—' : company.address),
                  InfoRow(label: 'Estado', value: company.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats empresa ──
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatCardData(
                label: 'Usuarios',
                value: '${companyUsers.length}',
                icon: Icons.people_rounded,
                color: T.accent,
              ),
              StatCardData(
                label: 'Activos',
                value:
                    '${companyUsers.where((u) => u.status == 'active').length}',
                icon: Icons.check_circle_rounded,
                color: T.success,
              ),
              StatCardData(
                label: 'Bloqueados',
                value:
                    '${companyUsers.where((u) => u.status == 'suspended').length}',
                icon: Icons.block_rounded,
                color: T.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Acciones rápidas con permisos superAdmin ──
          const Text('Gestión de la empresa',
              style: TextStyle(
                  color: T.textHi, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QuickAction(
                label: 'Usuarios',
                icon: Icons.people_rounded,
                color: T.accent,
                onTap: () => context.go(AppRoutesAuth.users),
              ),
              QuickAction(
                label: 'Roles',
                icon: Icons.shield_rounded,
                color: T.success,
                onTap: () => context.go(AppRoutesAuth.roles),
              ),
              QuickAction(
                label: 'Editar empresa',
                icon: Icons.edit_rounded,
                color: T.primary,
                onTap: () => context.go(AppRoutesAuth.companies),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Lista de usuarios ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Usuarios (${companyUsers.length})',
                  style: const TextStyle(
                      color: T.textHi,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => context.go(AppRoutesAuth.users),
                child: const Text('Ver todos',
                    style: TextStyle(color: T.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (companyUsers.isEmpty)
            const CardContainer(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('No hay usuarios en esta empresa',
                      style: TextStyle(color: T.textMid, fontSize: 13)),
                ),
              ),
            )
          else
            ...companyUsers.map((u) => UserMiniTile(user: u)),
        ],
      ),
    );
  }
}

// ── Info row simple ───────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label, value;
  const InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: T.textLo,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: T.textMid, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class SystemRolesTab extends StatelessWidget {
  final List<RoleDefinition> roles;
  const SystemRolesTab({required this.roles});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final role = roles[i];
        final appRole = AppRole.fromString(role.name);
        return CardContainer(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _roleColor(appRole).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shield_rounded,
                  color: _roleColor(appRole), size: 18),
            ),
            title: Row(
              children: [
                Text(role.displayName,
                    style: const TextStyle(
                        color: T.textHi,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: T.primaryLo,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Sistema',
                      style: TextStyle(
                          color: T.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: role.permissions
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: T.primaryLo,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: T.primary.withOpacity(0.2)),
                          ),
                          child: Text(
                            _permLabel(p),
                            style: const TextStyle(
                                color: T.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  String _permLabel(AppPermission p) => switch (p) {
        AppPermission.companiesView => '👁 Ver empresas',
        AppPermission.companiesCreate => '➕ Crear empresas',
        AppPermission.companiesEdit => '✏️ Editar empresas',
        AppPermission.companiesDelete => '🗑 Eliminar empresas',
        AppPermission.usersView => '👁 Ver usuarios',
        AppPermission.usersCreate => '➕ Crear usuarios',
        AppPermission.usersEdit => '✏️ Editar usuarios',
        AppPermission.usersDelete => '🗑 Eliminar usuarios',
        AppPermission.rolesView => '👁 Ver roles',
        AppPermission.rolesCreate => '➕ Crear roles',
        AppPermission.rolesEdit => '✏️ Editar roles',
        AppPermission.rolesDelete => '🗑 Eliminar roles',
        _ => p.value,
      };
  Color _roleColor(AppRole role) => switch (role) {
        AppRole.superAdmin => const Color(0xFFEF4444),
        AppRole.companyAdmin => const Color(0xFF6366F1),
        AppRole.manager => const Color(0xFF38BDF8),
        AppRole.editor => const Color(0xFF22C55E),
        AppRole.user => const Color(0xFFF59E0B),
      };
}

class NavGroupItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<NavItemData> children;
  final bool isAnyChildSelected;

  const NavGroupItem({
    required this.label,
    required this.icon,
    required this.children,
    required this.isAnyChildSelected,
  });

  @override
  State<NavGroupItem> createState() => NavGroupItemState();
}

class NavGroupItemState extends State<NavGroupItem>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isAnyChildSelected;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _expanded ? 1.0 : 0.0,
    );
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void Toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          child: Material(
            color: widget.isAnyChildSelected ? T.primaryLo : Colors.transparent,
            borderRadius: T.r8,
            child: InkWell(
              borderRadius: T.r8,
              onTap: Toggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    Icon(widget.icon,
                        size: 16,
                        color:
                            widget.isAnyChildSelected ? T.primary : T.textMid),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              widget.isAnyChildSelected ? T.primary : T.textMid,
                          fontWeight: widget.isAnyChildSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _rotate,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color:
                            widget.isAnyChildSelected ? T.primary : T.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.children.map((item) {
                      final selected = location == item.route;
                      return NavItem(
                        item: item,
                        selected: selected,
                        onTap: () {
                          Scaffold.of(context).closeDrawer();
                          context.go(item.route);
                        },
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class FloatingMenuButton extends StatelessWidget {
  const FloatingMenuButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: T.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => Scaffold.of(context).openDrawer(),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.menu_rounded, color: T.textMid, size: 20),
          ),
        ),
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: T.r12,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class CompanyMiniTile extends StatelessWidget {
  final Company company;
  const CompanyMiniTile({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: T.r12,
        border: const Border.fromBorderSide(BorderSide(color: T.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: T.primaryLo,
              borderRadius: T.r8,
            ),
            child:
                const Icon(Icons.business_rounded, color: T.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company.name,
                    style: const TextStyle(
                        color: T.textHi,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(company.email,
                    style: const TextStyle(color: T.textMid, fontSize: 11)),
              ],
            ),
          ),
          StatusBadge(status: company.status),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active' => (T.success, 'Activo'),
      'suspended' => (T.warning, 'Bloqueado'),
      'inactive' => (T.error, 'Inactivo'),
      _ => (T.textMid, status),
    };

    return Container(
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =============================================================================
// 5d. COMPANIES PAGE (solo superAdmin)
// =============================================================================

class CompaniesPage extends ConsumerWidget {
  const CompaniesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);
    final svc = ref.read(firebaseServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: T.primaryLo,
                      borderRadius: T.r12,
                      border: Border.all(color: T.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: T.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Empresas',
                          style: TextStyle(
                              color: T.textHi,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text('Gestión global de empresas',
                          style: TextStyle(color: T.textMid, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateCompanyDialog(context, svc),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Nueva empresa'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: companiesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: T.primary)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: T.error))),
              data: (companies) {
                if (companies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              color: T.primaryLo, shape: BoxShape.circle),
                          child: const Icon(Icons.business_outlined,
                              color: T.primary, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('No hay empresas registradas',
                            style: TextStyle(
                                color: T.textHi,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Crea la primera empresa del sistema',
                            style: TextStyle(color: T.textMid, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: companies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => CompanyCard(
                    company: companies[i],
                    svc: svc,
                    onEdit: () =>
                        showEditCompanyDialog(context, companies[i], svc),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCompanyDialog(BuildContext context, FirebaseService svc) {
    final nameCtrl = TextEditingController();
    final legalCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final adminEmailCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 780),
            child: Container(
              decoration: BoxDecoration(
                color: T.card,
                borderRadius: T.r20,
                border: Border.all(color: T.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: T.primaryLo, borderRadius: T.r8),
                          child: const Icon(Icons.add_business_rounded,
                              color: T.primary, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text('Nueva empresa',
                            style: TextStyle(
                                color: T.textHi,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: T.textMid, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: T.divider, height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (error != null) ErrorBannerData(message: error!),
                            const Text('Datos de la empresa',
                                style: TextStyle(
                                    color: T.textMid,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Nombre comercial',
                              controller: nameCtrl,
                              icon: Icons.business_rounded,
                              enabled: true,
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Razón social',
                              controller: legalCtrl,
                              icon: Icons.account_balance_rounded,
                              enabled: true,
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Email corporativo',
                              controller: emailCtrl,
                              icon: Icons.mail_outline_rounded,
                              enabled: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (!v.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Teléfono',
                              controller: phoneCtrl,
                              icon: Icons.phone_outlined,
                              enabled: true,
                              validator: null,
                            ),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Dirección',
                              controller: addressCtrl,
                              icon: Icons.location_on_outlined,
                              enabled: true,
                              validator: null,
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: T.divider),
                            const SizedBox(height: 12),
                            const Text('Administrador principal',
                                style: TextStyle(
                                    color: T.textMid,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Nombre del administrador',
                              controller: adminNameCtrl,
                              icon: Icons.person_outline_rounded,
                              enabled: true,
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Email del administrador',
                              controller: adminEmailCtrl,
                              icon: Icons.mail_outline_rounded,
                              enabled: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (!v.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            ProfileField(
                              label: 'Contraseña inicial',
                              controller: adminPassCtrl,
                              icon: Icons.lock_outline_rounded,
                              enabled: true,
                              obscure: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate())
                                          return;
                                        setState(() {
                                          loading = true;
                                          error = null;
                                        });
                                        final result = await svc.createCompany(
                                          name: nameCtrl.text,
                                          legalName: legalCtrl.text,
                                          email: emailCtrl.text,
                                          phone: phoneCtrl.text,
                                          address: addressCtrl.text,
                                          adminName: adminNameCtrl.text,
                                          adminEmail: adminEmailCtrl.text,
                                          adminPassword: adminPassCtrl.text,
                                        );
                                        if (!ctx.mounted) return;
                                        setState(() => loading = false);
                                        switch (result) {
                                          case Success():
                                            Navigator.pop(ctx);
                                          case Failure(:final message):
                                            setState(() => error = message);
                                        }
                                      },
                                child: loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Crear empresa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
