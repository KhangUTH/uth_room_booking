import 'package:flutter/material.dart';

import '../../../core/platform/app_permissions.dart';
import '../../../theme/app_colors.dart';

class AppPermissionsPage extends StatefulWidget {
  const AppPermissionsPage({super.key});

  @override
  State<AppPermissionsPage> createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage>
    with WidgetsBindingObserver {
  static const _permissions = [
    ('notifications', 'Thông báo', Icons.notifications_outlined),
    ('camera', 'Chụp ảnh', Icons.photo_camera_outlined),
    ('photos', 'Thư viện ảnh', Icons.photo_library_outlined),
  ];

  late Future<Map<String, String>> _statuses;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statuses = AppPermissions.readStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _statuses = AppPermissions.readStatuses());
    }
  }

  Future<void> _openSettings() async {
    if (await AppPermissions.openSettings() || !mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy mở Cài đặt trên thiết bị để quản lý quyền ứng dụng.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Cài đặt cấp quyền'),
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      bottom: false,
      minimum: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<Map<String, String>>(
          future: _statuses,
          builder: (context, snapshot) => ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
            children: [
              for (final (key, label, icon) in _permissions)
                _PermissionRow(
                  icon: icon,
                  label: label,
                  granted: snapshot.data?[key] == 'granted',
                  status: switch (snapshot.data?[key]) {
                    'granted' => 'Đã cấp',
                    'denied' => 'Chưa cấp',
                    'limited' => 'Cấp giới hạn',
                    'notRequired' => 'Chọn ảnh qua hệ thống',
                    _ =>
                      snapshot.connectionState == ConnectionState.done
                          ? 'Chưa xác định'
                          : 'Đang kiểm tra',
                  },
                ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: FilledButton(
        onPressed: _openSettings,
        child: const Text('Mở cài đặt thiết bị'),
      ),
    ),
  );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.granted,
  });

  final IconData icon;
  final String label;
  final String status;
  final bool granted;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.feedbackBackground,
          foregroundColor: AppColors.primary,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: granted
                  ? const Color(0xFFE4F6EA)
                  : const Color(0xFFF0F2F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: granted
                    ? const Color(0xFF187143)
                    : const Color(0xFF59636B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
