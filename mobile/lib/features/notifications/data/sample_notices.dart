import 'package:flutter/material.dart';

import '../models/app_notice.dart';

const List<AppNotice> demoNotices = [
  (
    id: 1,
    icon: Icons.notifications_none,
    title: 'Xác nhận đặt phòng máy tính',
    message: 'Phòng máy tính A1 đã được xác nhận cho bạn vào thứ Sáu, 14:00 tại Tầng 3, Nhà B.',
    metadata: 'Thứ Sáu, 14:00 · Tầng 3, Nhà B',
    age: '5 phút',
  ),
  (
    id: 2,
    icon: Icons.card_giftcard_outlined,
    title: 'Xác nhận sử dụng thiết bị',
    message: 'Thiết bị cần sử dụng đã được xác nhận cho bạn vào thứ Bảy, 09:00 tại Tầng 2, Nhà C.',
    metadata: 'Thứ Bảy, 09:00 · Tầng 2, Nhà C',
    age: '1 giờ',
  ),
  (
    id: 3,
    icon: Icons.task_alt,
    title: 'Thay đổi lịch nhận thiết bị',
    message: 'Lịch nhận thiết bị đã được chuyển sang Chủ nhật, 13:30 tại Khu A, Tầng 1.',
    metadata: 'Chủ nhật, 13:30 · Khu A, Tầng 1',
    age: '2 giờ',
  ),
  (
    id: 4,
    icon: Icons.people_outline,
    title: 'Thay đổi lịch sử dụng thiết bị',
    message: 'Lịch sử dụng thiết bị đã được chuyển sang thứ Hai, 16:00 tại Khu B, Tầng 2.',
    metadata: 'Thứ Hai, 16:00 · Khu B, Tầng 2',
    age: '3 giờ',
  ),
];

const List<AppNotice> technicianNotices = [
  (
    id: 101,
    icon: Icons.warning_amber_outlined,
    title: 'Sự cố mới cần tiếp nhận',
    message: 'Máy chiếu tại H203 không lên nét.',
    metadata: 'H203 · Báo 10 phút trước',
    age: '10 phút',
  ),
  (
    id: 102,
    icon: Icons.schedule,
    title: 'Công việc sắp đến hạn',
    message: 'Kiểm tra máy chiếu tại H302 theo lịch công việc.',
    metadata: 'H302 · 17:00 hôm nay',
    age: '30 phút',
  ),
  (
    id: 103,
    icon: Icons.check_circle_outline,
    title: 'Đề xuất bảo trì được duyệt',
    message: 'Đề xuất bảo trì cho phòng C3-105 đã được duyệt.',
    metadata: 'C3-105 · Thứ Sáu, 13/11',
    age: '1 giờ',
  ),
];
