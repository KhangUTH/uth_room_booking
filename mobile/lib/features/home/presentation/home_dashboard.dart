import 'package:flutter/material.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

import '../../../theme/app_text_sizes.dart';
import '../../notifications/data/sample_notices.dart';
import '../../notifications/models/app_notice.dart';
import '../widgets/home_action_cards.dart';
import '../widgets/home_notice_card.dart';
import '../widgets/home_stats_card.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.availableRooms,
    required this.onNotifications,
    required this.onRooms,
    required this.onEquipment,
    required this.onSchedule,
    required this.onHistory,
    this.notices = demoNotices,
    this.onRefresh,
    this.counts,
  });

  final int? availableRooms;
  final VoidCallback onNotifications;
  final VoidCallback onRooms;
  final VoidCallback onEquipment;
  final VoidCallback onSchedule;
  final VoidCallback onHistory;
  final List<AppNotice> notices;
  final Future<void> Function()? onRefresh;
  final ({int upcoming, int inUse, int used})? counts;

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.appBar,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeStatsCard(counts: counts),
                const SizedBox(height: 22),
                const _SectionTitle('Bạn muốn đăng ký gì?'),
                const SizedBox(height: 10),
                HomeActionRow(
                  first: HomeActionCard(
                    icon: Icons.desktop_windows_outlined,
                    title: 'Đặt phòng máy',
                    subtitle: availableRooms == null
                        ? 'Xem danh mục và chọn ca'
                        : 'Còn $availableRooms phòng trống',
                    onTap: onRooms,
                    featured: true,
                  ),
                  second: HomeActionCard(
                    icon: Icons.phone_android,
                    title: 'Thiết bị',
                    subtitle: 'Đăng ký sử dụng theo ca',
                    onTap: onEquipment,
                  ),
                ),
                const SizedBox(height: 12),
                HomeActionRow(
                  first: HomeActionCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Lịch của tôi',
                    subtitle: counts == null
                        ? 'Xem lịch đăng ký'
                        : '${counts!.upcoming} lịch sắp tới',
                    onTap: onSchedule,
                  ),
                  second: HomeActionCard(
                    icon: Icons.schedule,
                    title: 'Lịch sử',
                    subtitle: 'Xem lượt đã dùng',
                    onTap: onHistory,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: _SectionTitle('Thông báo mới')),
                    TextButton(
                      onPressed: onNotifications,
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                if (notices.isEmpty) const Text('Chưa có thông báo'),
                for (final notice in notices.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HomeNoticeCard(
                      notice.icon,
                      notice.title,
                      notice.age.isEmpty ? notice.message : notice.metadata,
                      notice.age,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    final refresh = onRefresh;
    return refresh == null
        ? content
        : RefreshIndicator(onRefresh: refresh, child: content);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: AppTextSizes.section,
      fontWeight: FontWeight.bold,
    ),
  );
}
