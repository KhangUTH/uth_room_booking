import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

class AppNotification {
  final String title;
  final String message;
  final String detail;
  final IconData icon;
  bool isRead = false;
  bool isSaved = false;

  AppNotification(this.title, this.message, this.detail, this.icon);
}

/// Dữ liệu và tùy chọn thông báo trong phiên đăng nhập hiện tại.
class NotificationController extends ChangeNotifier {
  final items = [
    AppNotification(
      'Xác nhận đặt phòng máy tính',
      'Phòng máy tính A1 đã được xác nhận cho bạn vào thứ Sáu, 14:00 tại Tầng 3, Nhà B.',
      'Thứ Sáu, 14:00 • Tầng 3, Nhà B',
      Icons.notifications_none,
    ),
    AppNotification(
      'Xác nhận sử dụng thiết bị',
      'Thiết bị cần sử dụng đã được xác nhận cho bạn vào thứ Bảy, 09:00 tại Tầng 2, Nhà C.',
      'Thứ Bảy, 09:00 • Tầng 2, Nhà C',
      Icons.card_giftcard_outlined,
    ),
    AppNotification(
      'Thay đổi lịch nhận thiết bị',
      'Lịch nhận thiết bị của bạn đã được chuyển sang Chủ nhật, 13:30 tại Khu A, Tầng 1.',
      'Chủ nhật, 13:30 • Khu A, Tầng 1',
      Icons.task_alt,
    ),
    AppNotification(
      'Thay đổi lịch sử dụng thiết bị',
      'Lịch sử dụng thiết bị của bạn đã được chuyển sang thứ Hai, 16:00 tại Khu B, Tầng 2.',
      'Thứ Hai, 16:00 • Khu B, Tầng 2',
      Icons.groups_outlined,
    ),
  ];
  bool receiveNotifications = true;

  void markRead(AppNotification item) {
    item.isRead = true;
    notifyListeners();
  }

  void toggleSaved(AppNotification item) {
    item.isSaved = !item.isSaved;
    notifyListeners();
  }

  void markAllRead() {
    for (final item in items) {
      item.isRead = true;
    }
    notifyListeners();
  }

  void setEnabled(bool value) {
    receiveNotifications = value;
    notifyListeners();
  }
}

class NotificationScope extends InheritedWidget {
  final NotificationController? controller;
  const NotificationScope({
    super.key,
    required this.controller,
    required super.child,
  });
  static NotificationController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NotificationScope>()
      ?.controller;
  @override
  bool updateShouldNotify(NotificationScope oldWidget) =>
      controller != oldWidget.controller;
}

void openNotifications(BuildContext context) {
  final controller = NotificationScope.maybeOf(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NotificationsPage(controller: controller),
    ),
  );
}

Future<void> openNotificationSettings(
  BuildContext context, {
  NotificationController? controller,
}) async {
  final existing = controller ?? NotificationScope.maybeOf(context);
  final settingsController = existing ?? NotificationController();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Tùy chỉnh thông báo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SwitchListTile(
              title: const Text('Nhận thông báo'),
              subtitle: const Text('Lưu tùy chọn trong phiên sử dụng này'),
              value: settingsController.receiveNotifications,
              onChanged: settingsController.setEnabled,
            ),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Đánh dấu tất cả đã đọc'),
              onTap: () {
                settingsController.markAllRead();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ),
  );

  if (existing == null) settingsController.dispose();
}

class NotificationsPage extends StatefulWidget {
  final NotificationController? controller;
  const NotificationsPage({super.key, this.controller});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController _controller =
      widget.controller ?? NotificationController();
  String _query = '';
  int _filter = 0;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _settings() =>
      openNotificationSettings(context, controller: _controller);

  void _openItem(AppNotification item) {
    _controller.markRead(item);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(item.message),
                const SizedBox(height: 12),
                Text(
                  item.detail,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _controller.toggleSaved(item),
                  icon: Icon(
                    item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: Text(
                    item.isSaved ? 'Bỏ lưu thông báo' : 'Lưu thông báo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      title: const Text(
        'Thông báo',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Cài đặt thông báo',
          onPressed: _settings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm thông báo...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF4F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _filter = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _filter == index
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              ['Tất cả', 'Chưa đọc', 'Đã lưu'][index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: _filter == index
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontWeight: _filter == index
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final items = _controller.items
                        .where(
                          (item) =>
                              (_filter != 1 || !item.isRead) &&
                              (_filter != 2 || item.isSaved) &&
                              '${item.title} ${item.message}'
                                  .toLowerCase()
                                  .contains(_query),
                        )
                        .toList();
                    if (items.isEmpty) {
                      return const Center(child: Text('Không có thông báo.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openItem(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFE6F4F5),
                                    foregroundColor: AppColors.primary,
                                    child: Icon(item.icon),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.message,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.detail,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        if (item.isSaved)
                                          const Icon(
                                            Icons.bookmark,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
