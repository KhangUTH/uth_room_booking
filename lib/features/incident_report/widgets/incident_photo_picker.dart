import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_colors.dart';

Future<Uint8List?> pickIncidentPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: _PhotoSourceTile(
                icon: Icons.photo_camera_outlined,
                label: 'Chụp ảnh',
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ),
            Expanded(
              child: _PhotoSourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Chọn từ thư viện',
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  final photo = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  return photo?.readAsBytes();
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      backgroundColor: const Color(0xFFF2F7F7),
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.border),
      minimumSize: const Size(0, 88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Icon(icon),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}
