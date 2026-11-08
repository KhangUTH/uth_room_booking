import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/support_request.dart';
import '../widgets/support_widgets.dart';
import 'contact_support_page.dart';
import 'report_issue_page.dart';

class SupportPage extends StatefulWidget {
  final String name;
  final String id;
  final bool isActive;
  final VoidCallback? onClose;
  final List<SupportRequest>? requests;
  const SupportPage({
    super.key,
    required this.name,
    required this.id,
    required this.isActive,
    this.onClose,
    this.requests,
  });

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  int _section = 0;
  late final List<SupportRequest> _requests = widget.requests ?? [];

  void _save(SupportRequest request) => setState(() => _requests.add(request));

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.isActive || (_section == 0 && widget.onClose == null),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && widget.isActive) {
        if (_section == 0) {
          widget.onClose?.call();
        } else {
          setState(() => _section = 0);
        }
      }
    },
    child: SafeArea(
      top: false,
      child: IndexedStack(
        index: _section,
        children: [
          _layout(
            'TRUNG TÂM\nHỖ TRỢ',
            Icons.phone_in_talk_outlined,
            _center(),
            isCenter: true,
          ),
          _layout('HƯỚNG DẪN\nSỬ DỤNG', Icons.menu_book_outlined, _guide()),
          _layout('CÂU HỎI\nTHƯỜNG GẶP', Icons.help_outline, _faq()),
          _layout(
            'BÁO CÁO\nSỰ CỐ',
            Icons.warning_amber_rounded,
            ReportIssuePage(onSave: _save),
          ),
          _layout(
            'LIÊN HỆ\nHỖ TRỢ',
            Icons.headset_mic_outlined,
            ContactSupportPage(name: widget.name, onSave: _save),
          ),
        ],
      ),
    ),
  );

  Widget _layout(
    String title,
    IconData icon,
    Widget child, {
    bool isCenter = false,
  }) => SupportLayout(
    name: widget.name,
    id: widget.id,
    title: title,
    icon: icon,
    isCenter: isCenter,
    onClose: isCenter ? widget.onClose : null,
    onBack: () => setState(() => _section = 0),
    child: child,
  );

  Widget _center() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Xin chào, bạn cần hỗ trợ gì?',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 20),
      _tile(
        1,
        Icons.menu_book_outlined,
        'Hướng dẫn sử dụng',
        'Xem hướng dẫn đăng ký phòng và mượn thiết bị',
      ),
      _tile(
        2,
        Icons.help_outline,
        'Câu hỏi thường gặp',
        'Giải đáp các thắc mắc khi sử dụng',
      ),
      _tile(
        3,
        Icons.warning_amber_rounded,
        'Báo cáo sự cố',
        'Phản ánh sự cố phòng máy và thiết bị',
      ),
      _tile(
        4,
        Icons.headset_mic_outlined,
        'Liên hệ hỗ trợ',
        'Gửi nội dung cần hỗ trợ tới nhà trường',
      ),
      if (_requests.isNotEmpty)
        TextButton.icon(
          icon: const Icon(Icons.drafts_outlined),
          label: Text('Bản mẫu đã lưu (${_requests.length})'),
          onPressed: _showDrafts,
        ),
    ],
  );

  Widget _tile(
    int section,
    IconData icon,
    String title,
    String subtitle,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.field,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4DB6B8),
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () => setState(() => _section = section),
      ),
    ),
  );

  Widget _guide() => const SupportPanel(
    child: Column(
      children: [
        ExpansionTile(
          title: Text('Tra cứu phòng và thiết bị'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tại Trang chủ, chọn “Xem thêm” trong danh sách phòng hoặc thiết bị để xem tình trạng trước khi đăng ký sử dụng.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Báo cáo sự cố'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn tab Báo cáo ở thanh điều hướng. Chọn loại sự cố, phòng và thiết bị liên quan, mô tả tình trạng và đính kèm ảnh nếu có.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Gửi nội dung cần hỗ trợ'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Vào Tôi → Trung tâm hỗ trợ → Liên hệ hỗ trợ. Điền họ tên, email và nội dung. Trong phiên bản thử nghiệm, yêu cầu được lưu dưới dạng bản mẫu trong phiên chạy.',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _faq() => const SupportPanel(
    child: Column(
      children: [
        ExpansionTile(
          title: Text('Tôi có bắt buộc đính kèm ảnh không?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Không. Ảnh minh chứng là tùy chọn. Bạn nên mô tả rõ tình trạng sự cố và vị trí phòng, thiết bị.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Thiết bị hỏng khi đang sử dụng thì làm gì?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ngừng sử dụng thiết bị, không tự tháo sửa. Chọn Báo cáo sự cố, loại Thiết bị và điền thông tin liên quan.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Yêu cầu đã được gửi tới nhà trường chưa?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Phiên bản hiện tại chưa kết nối backend. Các form chỉ lưu bản mẫu trong phiên chạy; dữ liệu sẽ mất khi khởi động lại ứng dụng.',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _showDrafts() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Bản mẫu đã lưu trong phiên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final request in _requests.reversed)
              ExpansionTile(
                title: Text(request.category),
                subtitle: Text(
                  '${request.createdAt.day}/${request.createdAt.month} · '
                  '${request.createdAt.hour.toString().padLeft(2, '0')}:${request.createdAt.minute.toString().padLeft(2, '0')}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final field in request.fields.entries)
                          Text('${field.key}: ${field.value}'),
                        if (request.evidence != null) ...[
                          const SizedBox(height: 12),
                          Image.memory(
                            request.evidence!,
                            height: 150,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stack) =>
                                const Text('Không thể hiển thị ảnh.'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
