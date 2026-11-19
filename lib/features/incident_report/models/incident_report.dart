import 'dart:typed_data';

import 'package:flutter/material.dart';

enum IncidentStatus {
  pending('Chờ tiếp nhận', Icons.schedule),
  approved('Đã duyệt', Icons.verified_outlined),
  inProgress('Đang xử lý', Icons.build_outlined),
  completed('Hoàn tất', Icons.check),
  cancelled('Đã hủy', Icons.cancel_outlined);

  const IncidentStatus(this.label, this.icon);
  final String label;
  final IconData icon;
}

typedef IncidentReport = ({
  int id,
  String title,
  String description,
  String type,
  String asset,
  String? assetId,
  String course,
  bool needsSupport,
  DateTime occurredAt,
  DateTime submittedAt,
  List<Uint8List> photos,
});
