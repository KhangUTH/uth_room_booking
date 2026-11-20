import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../booking/models/booking.dart';
import '../../booking/widgets/booking_history_card.dart';
import '../../incident_report/data/incident_report_store.dart';
import '../../incident_report/widgets/incident_report_details_sheet.dart';
import '../models/app_notice.dart';

const _muted = Color(0xFF596577);

void showNoticeDetails(
  BuildContext context,
  AppNotice notice,
  Future<Booking?>? bookingDetails,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => NoticeDetailsSheet(
      notice: notice,
      relatedDetails: bookingDetails == null
          ? null
          : FutureBuilder(
              future: bookingDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Chưa tải được chi tiết đăng ký.');
                }
                final booking = snapshot.data;
                return booking == null
                    ? const Text('Đăng ký này hiện không còn khả dụng.')
                    : BookingHistoryCard(booking: booking);
              },
            ),
    ),
  );
}

void showNoticeIncidentDetails(
  BuildContext context,
  IncidentReportStore incidents,
  StoredIncidentReport report,
) {
  final evidence = report.hasPhoto
      ? incidents.loadPhoto(report.id).catchError((Object _) => null)
      : null;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (context) => IncidentReportDetailsSheet(
      report: report.report,
      status: report.status,
      canCancel: false,
      updatedAt: report.updatedAt,
      evidence: evidence,
    ),
  );
}

class NoticeDetailsSheet extends StatelessWidget {
  const NoticeDetailsSheet({
    super.key,
    required this.notice,
    this.relatedDetails,
  });

  final AppNotice notice;
  final Widget? relatedDetails;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              backgroundColor: const Color(0xFFE3F2F3),
              foregroundColor: AppColors.primary,
              child: Icon(notice.icon),
            ),
          ),
          const SizedBox(height: 12),
          Text(notice.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(notice.metadata, style: const TextStyle(color: _muted)),
          const SizedBox(height: 12),
          SelectableText(notice.message),
          if (relatedDetails case final details?) ...[
            const SizedBox(height: 16),
            details,
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}
