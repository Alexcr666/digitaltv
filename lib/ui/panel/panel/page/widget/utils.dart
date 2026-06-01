
import 'package:digitaltv/ui/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class OrientationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const OrientationChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _C.primaryLo : _C.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _C.primary.withOpacity(0.5) : _C.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? _C.primary : _C.textMid),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: selected ? _C.primary : _C.textMid,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}



class DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T?> onChanged;
  const DropdownField({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _C.textMid),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                dropdownColor: _C.card,
                style: const TextStyle(color: _C.textHi, fontSize: 13),
                icon: const Icon(Icons.expand_more_rounded,
                    color: _C.textMid, size: 18),
                items: items
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(i.toString()),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class FilterTabs extends StatelessWidget {
  final String selected;
  final List<(String, String, int)> tabs;
  final ValueChanged<String> onChanged;
  const FilterTabs({
    required this.selected,
    required this.tabs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tabs.map((t) {
        final (id, label, count) = t;
        final isSelected = id == selected;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: AnimatedContainer(
            duration: 150.ms,
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? _C.primaryLo : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _C.primary.withOpacity(0.4) : _C.border),
            ),
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                        color: isSelected ? _C.primary : _C.textMid,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? _C.primary.withOpacity(0.2) : _C.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          color: isSelected ? _C.primary : _C.textLo,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
class SectionTitle extends StatelessWidget {
  final String text;
   SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}