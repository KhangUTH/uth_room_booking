import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/router/app_route.dart';

class EvidencePhotos extends StatelessWidget {
  const EvidencePhotos({
    super.key,
    required this.photos,
    this.onRemove,
    this.thumbnailSize = const Size.square(96),
  });

  final List<Uint8List> photos;
  final ValueChanged<int>? onRemove;
  final Size thumbnailSize;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (index, photo) in photos.indexed)
        Stack(
          children: [
            Material(
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context)
                    .pushNamed<void>(AppRoute.taskEvidence, arguments: photo),
                child: Image.memory(
                  photo,
                  semanticLabel: 'Ảnh minh chứng ${index + 1}',
                  width: thumbnailSize.width,
                  height: thumbnailSize.height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => SizedBox(
                    width: thumbnailSize.width,
                    height: thumbnailSize.height,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            if (onRemove case final remove?)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'Xóa ảnh ${index + 1}',
                  onPressed: () => remove(index),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
    ],
  );
}
