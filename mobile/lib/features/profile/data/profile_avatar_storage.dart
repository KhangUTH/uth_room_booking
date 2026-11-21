import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileAvatarStorage {
  ProfileAvatarStorage(this._client, String userId)
    : _path = '$userId/avatar.png';

  final SupabaseClient _client;
  final String _path;

  StorageFileApi get _bucket => _client.storage.from('profile-avatars');

  Future<Uint8List?> load() async {
    try {
      return await _bucket.download(_path);
    } on Exception {
      return null;
    }
  }

  Future<Uint8List?> pickAndSave() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      requestFullMetadata: false,
    );
    if (photo == null) return null;
    final codec = await ui.instantiateImageCodec(await photo.readAsBytes());
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null || data.lengthInBytes > 2 * 1024 * 1024) {
          throw const FormatException('Ảnh đại diện không hợp lệ.');
        }
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await _bucket.uploadBinary(
          _path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            cacheControl: '0',
            upsert: true,
          ),
        );
        return bytes;
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
