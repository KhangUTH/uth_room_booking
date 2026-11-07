import 'dart:typed_data';

// Bản mẫu chỉ lưu trong phiên; thay bằng repository/API khi có backend.
class SupportRequest {
  final String category;
  final Map<String, String> fields;
  final Uint8List? evidence;
  final DateTime createdAt;

  SupportRequest({
    required this.category,
    required Map<String, String> fields,
    this.evidence,
  }) : fields = Map.unmodifiable(fields),
       createdAt = DateTime.now();
}
