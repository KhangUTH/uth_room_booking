import 'dart:typed_data';

import 'package:flutter/material.dart';

class TaskEvidencePage extends StatelessWidget {
  const TaskEvidencePage({super.key, required this.image});

  final Uint8List image;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Ảnh minh chứng'),
    ),
    body: SafeArea(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.memory(
            image,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'Không thể hiển thị ảnh minh chứng.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}
