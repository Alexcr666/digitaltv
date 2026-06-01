
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:digitaltv/ui/panel/panel/page/model/model.dart';
import 'package:digitaltv/ui/panel/panel/page/pageDevice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';


class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}
class AddButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const AddButton({required this.label, required this.onTap});

  @override
  State<AddButton> createState() => AddButtonState();
}

class AddButtonState extends State<AddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF5254F0) : _C.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: _C.primary.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4)),
                  ]
                : [],
          ),
          child: Text(widget.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget action;
  const ScreenHeader({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _C.divider))),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: _C.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: _C.textMid, fontSize: 13)),
            ],
          ),
          const Spacer(),
          action,
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

abstract class _C {
  static const bg = Color(0xFF070B12);
  static const surface = Color(0xFF0C1018);
  static const card = Color(0xFF111827);
  static const cardHover = Color(0xFF151E2F);
  static const border = Color(0xFF1F2D45);
  static const borderFocus = Color(0xFF6366F1);
  static const primary = Color(0xFF6366F1);
  static const primaryLo = Color(0x1A6366F1);
  static const accent = Color(0xFF38BDF8);
  static const accentLo = Color(0x1A38BDF8);
  static const green = Color(0xFF22C55E);
  static const greenLo = Color(0x1A22C55E);
  static const amber = Color(0xFFF59E0B);
  static const amberLo = Color(0x1AF59E0B);
  static const red = Color(0xFFEF4444);
  static const redLo = Color(0x1AEF4444);
  static const purple = Color(0xFFA855F7);
  static const purpleLo = Color(0x1AA855F7);
  static const textHi = Color(0xFFF1F5FF);
  static const textMid = Color(0xFF7B8DB0);
  static const textLo = Color(0xFF2E3D5C);
  static const divider = Color(0xFF141E30);
}

class StatusDot extends StatefulWidget {
  final Color color;
  final bool animate;
  const StatusDot({required this.color, required this.animate});

  @override
  State<StatusDot> createState() => StatusDotState();
}

class StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1400.ms)
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_pulse.value * 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

SnackBar snack(String message) => SnackBar(
      content:
          Text(message, style: const TextStyle(color: _C.textHi, fontSize: 13)),
      backgroundColor: _C.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _C.border),
      ),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
class SheetLabel extends StatelessWidget {
  final String text;
  const SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: _C.textMid,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3)),
      );
}

class ContentTypeSelector extends StatelessWidget {
  final ContentType selected;
  final ValueChanged<ContentType> onChanged;
  const ContentTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ContentType.values.map((t) {
        final isSelected = t == selected;
        final color = _typeColor(t);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: 150.ms,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : _C.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color.withOpacity(0.5) : _C.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(_typeIcon(t),
                      size: 18, color: isSelected ? color : _C.textMid),
                  const SizedBox(height: 4),
                  Text(t.name[0].toUpperCase() + t.name.substring(1),
                      style: TextStyle(
                          color: isSelected ? color : _C.textMid,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _typeColor(ContentType t) {
    switch (t) {
      case ContentType.image:
        return _C.accent;
      case ContentType.video:
        return _C.purple;
      case ContentType.text:
        return _C.green;
      case ContentType.url:
        return _C.amber;
    }
  }

  IconData _typeIcon(ContentType t) {
    switch (t) {
      case ContentType.image:
        return Icons.image_rounded;
      case ContentType.video:
        return Icons.videocam_rounded;
      case ContentType.text:
        return Icons.text_fields_rounded;
      case ContentType.url:
        return Icons.language_rounded;
    }
  }
}

class IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const IconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.size = 18,
  });

  @override
  State<IconBtn> createState() => IconBtnState();
}

class IconBtnState extends State<IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 140.ms,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: _hovered
                      ? widget.color.withOpacity(0.4)
                      : Colors.transparent),
            ),
            child: Icon(widget.icon, size: widget.size, color: widget.color),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;
  const EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 52 : 72,
            height: compact ? 52 : 72,
            decoration: BoxDecoration(
              color: _C.primaryLo,
              shape: BoxShape.circle,
              border: Border.all(color: _C.primary.withOpacity(0.2)),
            ),
            child: Icon(icon, color: _C.primary, size: compact ? 24 : 32),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(title,
              style: TextStyle(
                  color: _C.textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 14 : 16)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(color: _C.textMid, fontSize: compact ? 11 : 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: 5,
      itemBuilder: (_, i) => SkeletonItem(index: i),
    );
  }
}

class SkeletonItem extends StatefulWidget {
  final int index;
  const SkeletonItem({required this.index});

  @override
  State<SkeletonItem> createState() => SkeletonItemState();
}

class SkeletonItemState extends State<SkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1400.ms)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 68,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Color.lerp(_C.card, _C.cardHover, _anim.value),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.index * 60));
  }
}

// ── Sheet components ──────────────────────────────────────────────────────────

class Sheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const Sheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: _C.border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: _C.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(subtitle,
                        style:
                            const TextStyle(color: _C.textMid, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: _C.textMid),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: _C.divider, height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 0.1,
          duration: 280.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 200.ms);
  }
}


class SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const SheetField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: _C.textHi, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.textLo, fontSize: 13),
        prefixIcon: Icon(icon, size: 16, color: _C.textMid),
        filled: true,
        fillColor: _C.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.red),
        ),
        errorStyle: const TextStyle(color: _C.red, fontSize: 10),
      ),
    );
  }
}

class SheetSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const SheetSubmitButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          disabledBackgroundColor: _C.card,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

class EditItemSheet extends StatefulWidget {
  final PlaylistItemModel item;
  final void Function(PlaylistItemModel) onSave;
  const EditItemSheet({required this.item, required this.onSave});

  @override
  State<EditItemSheet> createState() => EditItemSheetState();
}

class EditItemSheetState extends State<EditItemSheet> {
  late ContentType _type;
  late TextEditingController _titleCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _textCtrl;
  late int _duration;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.item.type;
    _titleCtrl = TextEditingController(text: widget.item.title);
    _urlCtrl = TextEditingController(text: widget.item.url ?? '');
    _textCtrl = TextEditingController(text: widget.item.textContent ?? '');
    _duration = widget.item.durationSeconds;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El título es obligatorio');
      return;
    }
    if (_type != ContentType.text && _urlCtrl.text.trim().isEmpty) {
      setState(() => _error = 'La URL es obligatoria');
      return;
    }
    if (_type == ContentType.text && _textCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El texto es obligatorio');
      return;
    }
    widget.onSave(PlaylistItemModel(
      id: widget.item.id,
      type: _type,
      title: _titleCtrl.text.trim(),
      url: _type != ContentType.text ? _urlCtrl.text.trim() : null,
      textContent: _type == ContentType.text ? _textCtrl.text.trim() : null,
      durationSeconds: _duration,
      order: widget.item.order,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: 'Editar elemento',
      subtitle: 'Modifica el contenido de este elemento',
      icon: Icons.edit_outlined,
      iconColor: _C.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ErrorBanner(message: _error!),
          const SheetLabel('Tipo de contenido'),
          const SizedBox(height: 8),
          ContentTypeSelector(
            selected: _type,
            onChanged: (t) => setState(() {
              _type = t;
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          const SheetLabel('Título *'),
          SheetField(
            controller: _titleCtrl,
            hint: 'Título del elemento',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 16),
          if (_type == ContentType.text) ...[
            const SheetLabel('Contenido de texto *'),
            SheetField(
              controller: _textCtrl,
              hint: 'Texto que se mostrará en pantalla',
              icon: Icons.text_fields_rounded,
              maxLines: 4,
            ),
          ] else ...[
            SheetLabel(_type == ContentType.image
                ? 'URL de la imagen *'
                : _type == ContentType.video
                    ? 'URL del video *'
                    : 'URL del sitio web *'),
            SheetField(
              controller: _urlCtrl,
              hint: _type == ContentType.image
                  ? 'https://example.com/imagen.jpg'
                  : _type == ContentType.video
                      ? 'https://example.com/video.mp4'
                      : 'https://tu-sitio.com',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
          ],
          const SizedBox(height: 16),
          SheetLabel('Duración: ${_duration}s'),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbColor: _C.accent,
              activeTrackColor: _C.accent,
              inactiveTrackColor: _C.border,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _duration.toDouble(),
              min: 3,
              max: 120,
              divisions: 39,
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('3s', style: TextStyle(color: _C.textLo, fontSize: 10)),
              Text('120s', style: TextStyle(color: _C.textLo, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 24),
          SheetSubmitButton(
            label: 'Guardar cambios',
            loading: false,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _C.textHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 10),
            Text(message,
                style: const TextStyle(
                    color: _C.textMid, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(color: _C.textMid, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Eliminar',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.redLo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: _C.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: _C.red, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
  }
}

SnackBar _snack(String message) => SnackBar(
      content:
          Text(message, style: const TextStyle(color: _C.textHi, fontSize: 13)),
      backgroundColor: _C.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _C.border),
      ),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );

class CredentialsDialog extends StatelessWidget {
  final String deviceName;
  final String username;
  final String password;
  const CredentialsDialog({
    required this.deviceName,
    required this.username,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _C.border)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: _C.greenLo,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.check_circle_rounded,
                        color: _C.green, size: 22)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dispositivo creado',
                        style: TextStyle(
                            color: _C.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(deviceName,
                        style:
                            const TextStyle(color: _C.textMid, fontSize: 12)),
                  ],
                )),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Credenciales del portal',
                        style: TextStyle(
                            color: _C.textMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    CredRow(
                        label: 'Usuario',
                        value: username,
                        icon: Icons.person_outline_rounded,
                        color: _C.primary),
                    const SizedBox(height: 10),
                    CredRow(
                        label: 'Contraseña',
                        value: password,
                        icon: Icons.lock_outline_rounded,
                        color: _C.accent),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _C.amberLo,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _C.amber.withOpacity(0.3))),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: _C.amber),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Guarda estas credenciales. El dispositivo las usará para acceder al portal.',
                                style: TextStyle(
                                    color: _C.amber,
                                    fontSize: 10,
                                    height: 1.5))),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: 'Usuario: $username\nContraseña: $password'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Credenciales copiadas'),
                        backgroundColor: _C.card,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _C.textMid,
                      side: const BorderSide(color: _C.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('Copiar todo'),
                    ],
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Listo',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class CredRow extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const CredRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  State<CredRow> createState() => CredRowState();
}

class CredRowState extends State<CredRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(widget.icon, size: 14, color: widget.color),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label,
            style: const TextStyle(color: _C.textLo, fontSize: 9)),
        const SizedBox(height: 1),
        Text(widget.value,
            style: TextStyle(
                color: widget.color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace')),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.value));
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _copied = false);
          });
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: _copied ? _C.greenLo : widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _copied
                      ? _C.green.withOpacity(0.4)
                      : widget.color.withOpacity(0.3))),
          child: Text(_copied ? '✓ Copiado' : 'Copiar',
              style: TextStyle(
                  color: _copied ? _C.green : widget.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}
class DateInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const DateInfoBox(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _C.textMid),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: _C.textLo, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: _C.textMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends ConsumerStatefulWidget {
  final DeviceModel device;
  final int index;
  const DeviceCard({required this.device, required this.index});

  @override
  ConsumerState<DeviceCard> createState() => DeviceCardState();
}

void showDeviceSchedules(BuildContext ctx, DeviceModel device) {
  showDialog(
    context: ctx,
    builder: (_) => DeviceSchedulesManagerDialog(device: device),
  );
}

class DeviceCardState extends ConsumerState<DeviceCard> {
  void _showCredentials(BuildContext ctx, DeviceModel device) async {
    // Obtener credenciales frescas de Firestore
    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(device.id)
        .get();
    if (!ctx.mounted) return;
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final username = data['portalUsername'] ?? '—';
    final password = data['portalPassword'] ?? '—';

    showDialog(
      context: ctx,
      builder: (_) => CredentialsDialog(
        deviceName: device.name,
        username: username,
        password: password,
      ),
    );
  }
  

  void _showAssignSchedules(BuildContext ctx, DeviceModel device) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignSchedulesSheet(device: device),
    );
  }

  bool _hovered = false;
  void _showEditDevice(BuildContext ctx, DeviceModel device) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditDeviceSheet(device: device),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final statusColor = d.status == DeviceStatus.online
        ? _C.green
        : d.status == DeviceStatus.warning
            ? _C.amber
            : _C.textLo;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 180.ms,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _hovered ? _C.cardHover : _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? _C.border.withOpacity(0.8) : _C.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: _C.primary.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4)),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status dot
              StatusDot(
                  color: statusColor, animate: d.status == DeviceStatus.online),
              const SizedBox(width: 14),

              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _C.primaryLo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.tv_rounded, color: _C.primary, size: 20),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: const TextStyle(
                            color: _C.textHi,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _Badge(
                            label: 'ID: ${d.uniqueDeviceId}', color: _C.textLo),
                        if (d.groupName != null) ...[
                          const SizedBox(width: 6),
                          _Badge(label: d.groupName!, color: _C.accent),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Playlist info
              if (d.currentPlaylistName != null)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.playlist_play_rounded,
                          size: 14, color: _C.textMid),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(d.currentPlaylistName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _C.textMid, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(width: 12),

              // Actions
              // Actions en _DeviceCard - reemplaza el Row de Actions completo:
              Row(
                children: [
                  IconBtn(
                    icon: Icons.key_rounded,
                    tooltip: 'Ver credenciales',
                    color: _C.amber,
                    onTap: () => _showCredentials(context, d),
                  ),
                  const SizedBox(width: 8),
                  IconBtn(
                    icon: Icons.edit_outlined,
                    tooltip: 'Editar',
                    color: _C.primary,
                    onTap: () => _showEditDevice(context, d),
                  ),
                  const SizedBox(width: 8),
                  IconBtn(
                    icon: Icons.playlist_add_rounded,
                    tooltip: 'Asignar playlists',
                    color: _C.accent,
                    onTap: () => showAssignPlaylist(context, d),
                  ),
                  const SizedBox(width: 8),
                  IconBtn(
                    icon: Icons.calendar_view_week_rounded,
                    tooltip: 'Programaciones',
                    color: _C.purple,
                    onTap: () => _showAssignSchedules(context, d),
                  ),
                  const SizedBox(width: 8),
                  IconBtn(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Eliminar',
                    color: _C.red,
                    onTap: () => _confirmDelete(context, d),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showAssignPlaylist(BuildContext ctx, DeviceModel device) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignPlaylistSheet(device: device),
    );
  }

  void openDisplay(BuildContext ctx, DeviceModel device) {
    // displayUrl viene como '/display/TOKEN' — extraemos el token
    final parts = device.displayUrl.split('/');
    final token = parts.isNotEmpty ? parts.last : device.displayUrl;

    if (token.isEmpty) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(_snack('Este dispositivo no tiene display asignado'));
      return;
    }

    // Navega usando go_router para respetar las rutas
   // ctx.go('/display/$token');
  }

  void _confirmDelete(BuildContext ctx, DeviceModel device) {
    showCupertinoDialog(
      context: ctx,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: const Text('Eliminar dispositivo'),
        content: Text(
            '¿Eliminar "${device.name}"? Esta acción no se puede deshacer.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
              await DeviceService().deleteDevice(device.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}