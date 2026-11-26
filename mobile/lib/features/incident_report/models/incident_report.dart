import 'dart:typed_data';

import 'package:flutter/material.dart';

const incidentPhotoMaxEdge = 720;

enum IncidentStatus {
  pending('Chờ tiếp nhận', Icons.schedule),
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
  DateTime submittedAt,
  List<Uint8List> photos,
});

typedef IncidentAssetOption = ({String? id, String name, String? detail});
