import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/images/encode_jpeg_photo.dart';

class ProfileAvatarStorage {
  ProfileAvatarStorage(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;
  static const _maxEdge = 512;
  String get _path => '$_userId/avatar.jpg';

  StorageFileApi get _bucket => _client.storage.from('profile-avatars');

  Future<Uint8List?> load() async {
    try {
      return await _bucket.download(_path);
    } on Exception {
      try {
        return await _bucket.download('$_userId/avatar.png');
      } on Exception {
        return null;
      }
    }
  }

  Future<Uint8List?> pickAndSave() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxEdge.toDouble(),
      maxHeight: _maxEdge.toDouble(),
      requestFullMetadata: false,
    );
    if (photo == null) return null;
    final bytes = await encodeJpegPhoto(
      await photo.readAsBytes(),
      maxEdge: _maxEdge,
    );
    await _bucket.uploadBinary(
      _path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        cacheControl: '0',
        upsert: true,
      ),
    );
    return bytes;
  }
}
