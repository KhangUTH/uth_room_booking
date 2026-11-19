import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as image;

Future<Uint8List> encodeJpegPhoto(
  Uint8List original, {
  required int maxEdge,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(original);
  final codec = await ui.instantiateImageCodecWithSize(
    buffer,
    getTargetSize: (width, height) {
      if (max(width, height) <= maxEdge) return const ui.TargetImageSize();
      return width >= height
          ? ui.TargetImageSize(width: maxEdge)
          : ui.TargetImageSize(height: maxEdge);
    },
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (data == null) {
        throw const FormatException('Không thể xử lý ảnh.');
      }
      return await compute(_encodeJpegPixels, (
        pixels: data,
        width: frame.image.width,
        height: frame.image.height,
      ));
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Uint8List _encodeJpegPixels(({ByteData pixels, int width, int height}) photo) {
  final raster = image.Image.fromBytes(
    width: photo.width,
    height: photo.height,
    bytes: photo.pixels.buffer,
    bytesOffset: photo.pixels.offsetInBytes,
    numChannels: 4,
    order: image.ChannelOrder.rgba,
  );
  return image.encodeJpg(raster, quality: 75);
}
