import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class IncidentTeachingSupportSwitch extends StatelessWidget {
  const IncidentTeachingSupportSwitch({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xFFFFF4F6) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: enabled ? const Color(0xFFEBC2CC) : _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: const Text(
          'Cần hỗ trợ ngay trong giờ dạy',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Dùng khi sự cố đang ảnh hưởng đến buổi học.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
        value: enabled,
        onChanged: onChanged,
      ),
    );
  }
}

class IncidentTypeOption extends StatelessWidget {
  const IncidentTypeOption({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.primary : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black87,
        side: BorderSide(color: selected ? AppColors.primary : _line),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? Colors.white24 : _pale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
