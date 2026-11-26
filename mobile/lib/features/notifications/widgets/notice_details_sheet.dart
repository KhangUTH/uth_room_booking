import 'dart:async';

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
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (context) =>
        _LiveIncidentDetails(store: incidents, initial: report),
  );
}

class _LiveIncidentDetails extends StatefulWidget {
  const _LiveIncidentDetails({required this.store, required this.initial});

  final IncidentReportStore store;
  final StoredIncidentReport initial;

  @override
  State<_LiveIncidentDetails> createState() => _LiveIncidentDetailsState();
}

class _LiveIncidentDetailsState extends State<_LiveIncidentDetails> {
  late var _report = widget.initial;
  late final _evidence = widget.initial.hasPhoto
      ? widget.store.loadPhoto(widget.initial.id).catchError((Object _) => null)
      : null;
  late final Timer _timer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _refreshing = true;
    try {
      final report = await widget.store.reportById(widget.initial.id);
      if (mounted && report != null && report != _report) {
        setState(() => _report = report);
      }
    } catch (_) {
      // Keep the last loaded details until the next successful refresh.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IncidentReportDetailsSheet(
    report: _report.report,
    status: _report.status,
    canCancel: false,
    updatedAt: _report.updatedAt,
    evidence: _evidence,
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
