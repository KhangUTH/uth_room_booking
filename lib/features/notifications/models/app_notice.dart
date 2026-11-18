import 'package:flutter/widgets.dart';

typedef AppNotice = ({
  int id,
  IconData icon,
  String title,
  String message,
  String metadata,
  String age,
});

extension IncidentNotice on AppNotice {
  String? get incidentTitle {
    const prefix = 'Báo cáo “';
    final suffix = switch (title) {
      'Kỹ thuật viên đã nhận công việc' => '” đã được tiếp nhận và đang xử lý.',
      'Kỹ thuật viên đã hoàn tất công việc' =>
        '” đã được xử lý xong. Bạn có thể xem lại trong Báo cáo của tôi.',
      _ => null,
    };
    if (suffix == null ||
        !message.startsWith(prefix) ||
        !message.endsWith(suffix) ||
        message.length <= prefix.length + suffix.length) {
      return null;
    }
    return message.substring(prefix.length, message.length - suffix.length);
  }
}
