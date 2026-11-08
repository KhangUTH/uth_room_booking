import 'package:flutter/material.dart';
import 'package:uth_room_booking/shared/layouts/header.dart';

/// Chỉ cung cấp nội dung KTV; bố cục lấy từ header dùng chung.
class TechnicianHeader extends StatelessWidget {
  final String name;
  final String id;
  final String? title;

  const TechnicianHeader({
    super.key,
    required this.name,
    required this.id,
    this.title,
  });

  @override
  Widget build(BuildContext context) => MyHeader(
    name: name,
    id: id,
    isTechnician: true,
    title: title,
    subtitle: title == null ? null : 'Phòng/thiết bị được phân công',
  );
}
