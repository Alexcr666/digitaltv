import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/auth/firebaseService.dart';
import 'package:digitaltv/auth/utils/utils.dart';
import 'package:digitaltv/logo.dart';
import 'package:digitaltv/utils/permission_label.dart';
import 'package:flutter/material.dart';

abstract class T {
  // Surface
  static const bg = Color(0xFF080C14);
  static const surface = Color(0xFF0E1420);
  static const card = Color(0xFF131B2B);
  static const cardHover = Color(0xFF172035);
  static const border = Color(0xFF1E2D47);
  static const divider = Color(0xFF1A2540);

  // Brand
  static const primary = Color(0xFF45c4c4);
  static const primaryLo = Color(0x1A45c4c4);
  static const primaryMid = Color(0x3345c4c4);
  static const accent = Color(0xFF38BDF8);

  // Text
  static const textHi = Color(0xFFF0F4FF);
  static const textMid = Color(0xFF8B9CC8);
  static const textLo = Color(0xFF3D4F72);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const errorLo = Color(0x1AEF4444);

  // Radius
  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: error,
        ),
        textTheme: const TextTheme().apply(
          bodyColor: textMid,
          displayColor: textHi,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          hintStyle: const TextStyle(color: textLo, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: r12, borderSide: const BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: r12, borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: r12,
              borderSide: const BorderSide(color: primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: r12, borderSide: const BorderSide(color: error)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: r12,
              borderSide: const BorderSide(color: error, width: 1.5)),
          errorStyle: const TextStyle(color: error, fontSize: 11),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: card,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: r12),
            minimumSize: const Size(double.infinity, 48),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
        cardTheme: CardTheme(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: r16,
            side: const BorderSide(color: border),
          ),
        ),
      );
}

class NavItem extends StatelessWidget {
  final NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  const NavItem(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? T.primaryLo : Colors.transparent,
        borderRadius: T.r8,
        child: InkWell(
          borderRadius: T.r8,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 16, color: selected ? T.primary : T.textMid),
                const SizedBox(width: 10),
                Text(item.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? T.primary : T.textMid,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showEditCompanyDialog(
    BuildContext context, Company company, FirebaseService svc) {
  final nameCtrl = TextEditingController(text: company.name);
  final legalCtrl = TextEditingController(text: company.legalName);
  final emailCtrl = TextEditingController(text: company.email);
  final phoneCtrl = TextEditingController(text: company.phone);
  final addressCtrl = TextEditingController(text: company.address);
  bool loading = false;
  String? error;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: T.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: T.border),
        ),
        title: Text('Editar: ${company.name}',
            style: const TextStyle(color: T.textHi)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ErrorBannerData(message: error!),
                ProfileField(
                  label: 'Nombre comercial',
                  controller: nameCtrl,
                  icon: Icons.business_rounded,
                  enabled: true,
                  validator: null,
                ),
                const SizedBox(height: 10),
                ProfileField(
                  label: 'Razón social',
                  controller: legalCtrl,
                  icon: Icons.account_balance_rounded,
                  enabled: true,
                  validator: null,
                ),
                const SizedBox(height: 10),
                ProfileField(
                  label: 'Email',
                  controller: emailCtrl,
                  icon: Icons.mail_outline_rounded,
                  enabled: true,
                  validator: null,
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: T.textMid)),
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    final updated = Company(
                      id: company.id,
                      name: nameCtrl.text.trim(),
                      legalName: legalCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      logoUrl: company.logoUrl,
                      status: company.status,
                      createdAt: company.createdAt,
                      updatedAt: DateTime.now(),
                    );
                    final result = await svc.updateCompany(updated);
                    if (!ctx.mounted) return;
                    setState(() => loading = false);
                    switch (result) {
                      case Success():
                        Navigator.pop(ctx);
                      case Failure(:final message):
                        setState(() => error = message);
                    }
                  },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

class AuthScaffold extends StatelessWidget {
  final Widget child;
  const AuthScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated bg orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  T.primary.withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  T.accent.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Grid overlay
          CustomPaint(painter: GridPainter()),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: T.card,
                      borderRadius: T.r20,
                      border: const Border.fromBorderSide(
                          BorderSide(color: T.border)),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = T.border.withOpacity(0.4)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class AuthHeader extends StatelessWidget {
  final String title, subtitle;
  const AuthHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLogo(height: 250, showBadge: false),
        Text(title,
            style: const TextStyle(
                color: T.textHi,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: T.textMid, fontSize: 13)),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: T.textMid,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3)),
      );
}

class SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const SubmitButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}

class ToggleLink extends StatelessWidget {
  final String prompt, action;
  final VoidCallback onTap;
  const ToggleLink({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$prompt ',
              style: const TextStyle(color: T.textMid, fontSize: 13)),
          GestureDetector(
            onTap: onTap,
            child: Text(action,
                style: const TextStyle(
                    color: T.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: T.r8,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: T.r8,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class StatCardData extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: T.r16,
        border: const Border.fromBorderSide(BorderSide(color: T.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: T.r8,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  color: T.textHi, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: T.textMid, fontSize: 11)),
        ],
      ),
    );
  }
}

class ErrorBannerData extends StatelessWidget {
  final String message;
  const ErrorBannerData({required this.message});

  @override
  Widget build(BuildContext context) {
    return Banner(
        message: message, color: T.error, icon: Icons.error_outline_rounded);
  }
}

class Banner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  const Banner({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: T.r12,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// _RoleSelector — widget completo corregido
class RoleSelector extends StatelessWidget {
  final AppRole selected;
  final ValueChanged<AppRole> onChanged;
  const RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: AppRole.values.map((role) {
        final isSelected = role == selected;
        final color = role.color; // ← extensión
        return GestureDetector(
          onTap: () => onChanged(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.5) : T.card,
              borderRadius: T.r12,
              border: Border.all(
                color: isSelected ? color.withOpacity(0.5) : T.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.15 : 0.07),
                    borderRadius: T.r8,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 15,
                    color: color.withOpacity(isSelected ? 1.0 : 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: TextStyle(
                          color: isSelected ? T.textHi : T.textMid,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      Text(
                        role.description, // ← extensión
                        style: const TextStyle(color: T.textLo, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class Avatar extends StatelessWidget {
  final AppUser? user;
  final double size;
  const Avatar({this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    final initials = (user?.name.isNotEmpty == true)
        ? user!.name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: T.primaryMid,
        shape: BoxShape.circle,
        border: Border.all(color: T.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  InitialsWidget(initials: initials, size: size))
          : InitialsWidget(initials: initials, size: size),
    );
  }
}

class InitialsWidget extends StatelessWidget {
  final String initials;
  final double size;
  const InitialsWidget({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(initials,
            style: TextStyle(
                color: T.primary,
                fontSize: size * 0.32,
                fontWeight: FontWeight.w700)),
      );
}

// _RoleChip — widget completo corregido
class RoleChip extends StatelessWidget {
  final AppRole role;
  const RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role.color; // ← extensión, sin duplicar lógica
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// _PermBadge — widget completo corregido
class PermBadge extends StatelessWidget {
  final AppPermission permission;
  const PermBadge({required this.permission});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: T.primaryLo,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: T.primary.withOpacity(0.2)),
        ),
        child: Text(
          permission.value, // ← extensión
          style: const TextStyle(
            color: T.primary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

class CardContainer extends StatelessWidget {
  final Widget child;
  const CardContainer({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: T.card,
          borderRadius: T.r16,
          border: const Border.fromBorderSide(BorderSide(color: T.border)),
        ),
        child: child,
      );
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => CardContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: T.textHi,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );
}

class FormRow extends StatelessWidget {
  final List<Widget> children;
  const FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      return Column(
        children: children
            .expand((c) => [c, const SizedBox(height: 14)])
            .take(children.length * 2 - 1)
            .toList(),
      );
    }
    return Row(
      children: children
          .expand((c) => [Expanded(child: c), const SizedBox(width: 14)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final String? Function(String?)? validator;

  const ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.enabled,
    this.obscure = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          style: inputStyle,
          decoration: inputDeco(hint: label, icon: icon).copyWith(
            fillColor: enabled ? T.card : T.surface,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  const InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: T.r12,
              border: const Border.fromBorderSide(BorderSide(color: T.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 8),
                Text(value,
                    style: const TextStyle(color: T.textMid, fontSize: 13)),
              ],
            ),
          ),
        ],
      );
}
