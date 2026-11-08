import 'package:flutter/material.dart';
import 'package:uth_room_booking/shared/layouts/header.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

class SupportLayout extends StatelessWidget {
  final String name;
  final String id;
  final String title;
  final IconData icon;
  final bool isCenter;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget child;

  const SupportLayout({
    super.key,
    required this.name,
    required this.id,
    required this.title,
    required this.icon,
    required this.child,
    this.isCenter = false,
    this.onBack,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          MyHeader(
            showBackButton: onClose != null,
            onBack: onClose,
            name: name,
            id: id,
            titleIcon: icon,
            title: isCenter ? title : null,
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isCenter)
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Về trung tâm hỗ trợ',
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SupportPanel extends StatelessWidget {
  final Widget child;
  const SupportPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.field,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class SupportField extends StatelessWidget {
  final String label;
  final Widget child;
  const SupportField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

String? requiredSupportText(String? value) =>
    value == null || value.trim().isEmpty
    ? 'Vui lòng nhập thông tin này'
    : null;

Future<void> showSupportSaved(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Đã lưu bản mẫu'),
    content: const Text(
      'Thông tin đã được lưu trong phiên chạy thử. Ứng dụng chưa kết nối hệ thống gửi yêu cầu hỗ trợ.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đã hiểu'),
      ),
    ],
  ),
);
