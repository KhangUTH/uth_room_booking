import 'package:flutter/material.dart';

import '../data/profile_avatar_storage.dart';

class ProfileAvatarController extends ChangeNotifier {
  ProfileAvatarController(this.storage);

  final ProfileAvatarStorage? storage;
  ImageProvider? _image;
  bool _saving = false;
  bool _disposed = false;

  ImageProvider? get image => _image;
  bool get saving => _saving;

  Future<void> load() async {
    final bytes = await storage?.load();
    if (_disposed || bytes == null || image != null) return;
    _image = MemoryImage(bytes);
    notifyListeners();
  }

  Future<void> change(BuildContext context) async {
    final source = storage;
    if (source == null || saving) return;
    _saving = true;
    notifyListeners();
    try {
      final bytes = await source.pickAndSave();
      if (!_disposed && bytes != null) _image = MemoryImage(bytes);
    } catch (_) {
      if (!_disposed && context.mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Không thể lưu ảnh đại diện. Vui lòng thử lại.'),
            ),
          );
      }
    } finally {
      if (!_disposed) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
