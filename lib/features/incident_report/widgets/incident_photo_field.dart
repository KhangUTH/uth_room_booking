import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../shared/widgets/evidence_photos.dart';
import 'incident_report_labels.dart';

class IncidentPhotoField extends StatelessWidget {
  const IncidentPhotoField({
    super.key,
    required this.photo,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? photo;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const IncidentFieldTitle('Hình ảnh minh chứng (tối đa 1)'),
      Row(
        spacing: 12,
        children: [
          OutlinedButton(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(84, 80),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                const Icon(Icons.add_a_photo_outlined, size: 20),
                Text(
                  photo == null ? 'Thêm ảnh' : 'Đổi ảnh',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          if (photo case final selected?)
            Flexible(
              child: EvidencePhotos(
                photos: [selected],
                thumbnailSize: const Size(112, 80),
                onRemove: onRemove == null ? null : (_) => onRemove!(),
              ),
            ),
        ],
      ),
    ],
  );
}
