import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/widgets/evidence_photos.dart';

import '../models/incident_report.dart';
import 'incident_report_labels.dart';
import 'incident_report_progress.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class IncidentReportDetailsSheet extends StatelessWidget {
  const IncidentReportDetailsSheet({
    super.key,
    required this.report,
    required this.status,
    required this.canCancel,
    this.updatedAt,
    this.evidence,
  });

  final IncidentReport report;
  final IncidentStatus status;
  final bool canCancel;
  final DateTime? updatedAt;
  final Future<Uint8List?>? evidence;

  @override
  Widget build(BuildContext sheetContext) => FractionallySizedBox(
    heightFactor: .95,
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: [
                Center(
                  child: Image.asset('assets/images/logo/logo.jpg', height: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mã báo cáo #SC-${report.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IncidentReportLabels(report: report, status: status),
                ),
                if (status != IncidentStatus.cancelled) ...[
                  const SizedBox(height: 16),
                  IncidentReportProgress(status: status),
                ],
                const SizedBox(height: 14),
                _ReportInfo(
                  icon: Icons.place_outlined,
                  label: 'Vị trí / đối tượng',
                  value: '${report.type} · ${report.asset}',
                ),
                const SizedBox(height: 10),
                _ReportInfo(
                  icon: Icons.schedule,
                  label: 'Thời gian gửi báo cáo',
                  value: formatIncidentDateTime(
                    sheetContext,
                    report.submittedAt,
                  ),
                ),
                if (report.course.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ReportInfo(
                    icon: Icons.school_outlined,
                    label: 'Lớp học phần đang dạy',
                    value: report.course,
                  ),
                ],
                const IncidentFieldTitle('Mô tả chi tiết'),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F7F7),
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 3),
                      ),
                    ),
                    child: Text(report.description),
                  ),
                ),
                const IncidentFieldTitle('Hình ảnh minh chứng'),
                if (evidence case final request?)
                  FutureBuilder<Uint8List?>(
                    future: request,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data == null) {
                        return const _ReportPlaceholder(
                          Icons.image_outlined,
                          'Không tải được ảnh. Mở lại chi tiết để thử lại.',
                        );
                      }
                      final photo = snapshot.data;
                      return photo == null
                          ? const LinearProgressIndicator()
                          : EvidencePhotos(photos: [photo]);
                    },
                  )
                else if (report.photos.isEmpty)
                  const _ReportPlaceholder(
                    Icons.image_outlined,
                    'Chưa có ảnh đính kèm',
                  )
                else
                  EvidencePhotos(photos: report.photos),
                const IncidentFieldTitle('Cập nhật từ kỹ thuật'),
                _ReportPlaceholder(
                  Icons.chat_bubble_outline,
                  updatedAt == null
                      ? status == IncidentStatus.cancelled
                            ? 'Báo cáo đã hủy.'
                            : 'Đang chờ kỹ thuật viên tiếp nhận.'
                      : '${status.label} lúc ${formatIncidentDateTime(sheetContext, updatedAt!)}',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                if (canCancel) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmReportCancellation(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFAD3037),
                        side: const BorderSide(color: Color(0xFFAD3037)),
                      ),
                      child: const Text(
                        'Hủy báo cáo',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> _confirmReportCancellation(BuildContext sheetContext) async {
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('Hủy báo cáo này?'),
        content: const Text('Báo cáo sẽ chuyển sang trạng thái Đã hủy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Giữ báo cáo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFAD3037),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed == true && sheetContext.mounted) {
      Navigator.pop(sheetContext, true);
    }
  }
}

class _ReportInfo extends StatelessWidget {
  const _ReportInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F7F7),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _muted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    ),
  );
}

class _ReportPlaceholder extends StatelessWidget {
  const _ReportPlaceholder(this.icon, this.message);

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _line),
    ),
    child: Column(
      spacing: 6,
      children: [
        Icon(icon, color: const Color(0xFF84A3A4), size: 22),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}
