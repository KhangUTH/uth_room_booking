import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../auth/models/user_role.dart';

class IncidentReporterCard extends StatelessWidget {
  const IncidentReporterCard({
    super.key,
    required this.name,
    required this.id,
    required this.role,
  });

  final String name;
  final String id;
  final UserRole role;
  static const _pale = Color(0xFFDCEFEF);
  static const _line = Color(0xFFD6E6E7);
  static const _muted = Color(0xFF526E74);

  @override
  Widget build(BuildContext context) {
    final (roleLabel, idLabel) = switch (role) {
      UserRole.student => ('Sinh viên', 'MSSV'),
      UserRole.teacher => ('Giảng viên', 'MSGV'),
      UserRole.technician => ('Nhân viên kỹ thuật', 'Mã NV'),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: _pale,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.person_outline, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Người báo cáo',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _pale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roleLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '$idLabel: $id',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
