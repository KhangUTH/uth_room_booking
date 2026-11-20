import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../auth/models/user_role.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class ProfileSupportPage extends StatelessWidget {
  const ProfileSupportPage({
    super.key,
    required this.role,
    required this.terms,
  });

  static const helpTitle = 'Trung tâm trợ giúp';
  static const termsTitle = 'Điều khoản sử dụng';
  final UserRole role;
  final bool terms;

  static const _usage = [
    (
      'Phạm vi sử dụng',
      'UTH Lab là bản thử nghiệm đồ án phục vụ đăng ký sử dụng phòng máy và thiết bị tại UTH Cơ sở 3.',
    ),
    (
      'Sử dụng đúng lịch',
      'Kiểm tra trạng thái duyệt trước khi đến. Sử dụng đúng phòng, thiết bị và khung giờ đã được duyệt.',
    ),
    (
      'Giữ gìn phòng và thiết bị',
      'Giữ vệ sinh, sắp xếp lại thiết bị và tắt quạt, đèn, nguồn điện của thiết bị đã dùng trước khi rời phòng.',
    ),
    (
      'Bảo vệ tài khoản và thông tin cá nhân',
      'Giữ bí mật mật khẩu. Khi gửi ảnh minh chứng, chỉ chụp khu vực cần thiết và tránh để lộ thông tin cá nhân của người khác.',
    ),
    (
      'Báo sự cố',
      'Khi phát hiện hư hỏng, gửi báo cáo trong app và mô tả rõ vị trí để kỹ thuật viên kiểm tra.',
    ),
  ];

  List<(String, String, IconData)> get _help => [
    if (role == UserRole.technician) ...[
      (
        'Làm sao nhận và hoàn tất công việc?',
        'Mở tab Công việc, xem chi tiết sự cố rồi bấm Nhận việc. Việc sẽ chuyển sang Đang xử lý. Sau khi xử lý xong, đánh dấu Hoàn tất.',
        Icons.assignment_outlined,
      ),
    ] else ...[
      (
        'Làm sao đăng ký phòng máy hoặc thiết bị?',
        'Vào Lịch, chọn Phòng máy hoặc Thiết bị, ngày và ca còn trống. '
            '${role == UserRole.teacher ? 'Khi đặt phòng máy, chọn lớp học phần trước khi xác nhận.' : 'Khi đặt phòng máy, chọn số người từ 10 trở lên.'}',
        Icons.event_available_outlined,
      ),
      (
        'Xem trạng thái hoặc hủy đăng ký ở đâu?',
        'Vào Lịch → Của tôi và mở chi tiết đăng ký. Với đơn đang chờ duyệt, bạn có thể chọn hủy và xác nhận.',
        Icons.checklist_outlined,
      ),
      (
        'Gửi và theo dõi báo cáo sự cố ở đâu?',
        'Vào Báo cáo → Tạo báo cáo, chọn phòng hoặc thiết bị và mô tả sự cố. Mở Báo cáo của tôi để xem tiến độ và ảnh minh chứng đã gửi.',
        Icons.warning_amber_rounded,
      ),
    ],
    (
      'Vì sao tôi không nhận được thông báo?',
      'Trên Android, vào Cá nhân → Nhận thông báo và bật công tắc. Kiểm tra thêm quyền Thông báo trong cài đặt thiết bị. Bạn có thể mở chuông trong app để xem hộp thư.',
      Icons.notifications_none,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(terms ? termsTitle : helpTitle),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      top: false,
      child: terms
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo/logo.jpg',
                      height: 48,
                      fit: BoxFit.contain,
                      semanticLabel: 'Logo UTH',
                    ),
                  ),
                ),
                for (final (heading, body) in _usage)
                  _SupportEntry(heading: heading, body: body),
              ],
            )
          : _buildHelp(),
    ),
    bottomNavigationBar: terms ? null : _buildContactBar(context),
  );

  Widget _buildHelp() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    children: [
      Center(
        child: Image.asset(
          'assets/images/logo/logo.jpg',
          height: 36,
          fit: BoxFit.contain,
          semanticLabel: 'Logo UTH',
        ),
      ),
      const SizedBox(height: 16),
      for (final (heading, body, icon) in _help)
        _SupportEntry(
          key: ValueKey(heading),
          heading: heading,
          body: body,
          expandable: true,
          icon: icon,
        ),
    ],
  );

  Widget _buildContactBar(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: Card(
      color: _pale,
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Icon(Icons.support_agent),
        ),
        title: const Text('Vẫn cần hỗ trợ?'),
        subtitle: const Text('Liên hệ quản trị viên phòng máy'),
        trailing: FilledButton(
          onPressed: () => _showContact(context),
          child: const Text('Liên hệ'),
        ),
      ),
    ),
  );

  void _showContact(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        scrollable: true,
        title: Column(
          children: [
            Image.asset(
              'assets/images/logo/logo.jpg',
              height: 38,
              fit: BoxFit.contain,
              semanticLabel: 'Logo UTH',
            ),
            const SizedBox(height: 14),
            const Text(
              'Liên hệ hỗ trợ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: AppColors.textDark),
                        children: [
                          TextSpan(
                            text: 'Quản trị viên phòng máy\n',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: 'Liên hệ trực tiếp tại UTH Cơ sở 3'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nếu gặp sự cố với phòng hoặc thiết bị, hãy gửi báo cáo trong UTH Lab.',
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _SupportEntry extends StatelessWidget {
  const _SupportEntry({
    super.key,
    required this.heading,
    required this.body,
    this.expandable = false,
    this.icon = Icons.description_outlined,
  });

  final String heading;
  final String body;
  final bool expandable;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      heading,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
    final description = Text(
      body,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: _muted, height: 1.5),
    );
    final badge = CircleAvatar(
      radius: 18,
      backgroundColor: _pale,
      foregroundColor: AppColors.primary,
      child: Icon(icon, size: 18),
    );
    final idleShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _line),
    );
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.only(bottom: expandable ? 8 : 12),
      shape: expandable ? idleShape.copyWith(side: BorderSide.none) : idleShape,
      clipBehavior: Clip.antiAlias,
      child: expandable
          ? ExpansionTile(
              leading: badge,
              title: title,
              dense: true,
              collapsedShape: idleShape,
              shape: idleShape.copyWith(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedAlignment: Alignment.centerLeft,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [description],
            )
          : ListTile(
              contentPadding: const EdgeInsets.fromLTRB(14, 8, 16, 10),
              leading: badge,
              titleAlignment: ListTileTitleAlignment.top,
              title: title,
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: description,
              ),
            ),
    );
  }
}
