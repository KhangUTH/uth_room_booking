import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/incident_report.dart';
import 'incident_report_labels.dart';

class IncidentReportHistory extends StatelessWidget {
  const IncidentReportHistory({
    super.key,
    required this.reports,
    required this.statusFor,
    required this.onOpen,
    this.onRefresh,
  });

  final List<IncidentReport> reports;
  final IncidentStatus Function(IncidentReport) statusFor;
  final ValueChanged<IncidentReport> onOpen;
  final Future<void> Function()? onRefresh;

  static const _pale = Color(0xFFDCEFEF);
  static const _line = Color(0xFFD6E6E7);

  @override
  Widget build(BuildContext context) {
    final content = _buildList();
    final refresh = onRefresh;
    return refresh == null
        ? content
        : RefreshIndicator(onRefresh: refresh, child: content);
  }

  Widget _buildList() {
    if (reports.isEmpty) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bạn chưa gửi báo cáo sự cố nào.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _line),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => onOpen(report),
            leading: const CircleAvatar(
              backgroundColor: _pale,
              foregroundColor: AppColors.primary,
              child: Icon(Icons.assignment_outlined),
            ),
            title: Text(
              report.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.asset),
                Text(
                  'Lưu lúc ${formatIncidentDateTime(context, report.submittedAt)}',
                ),
                const SizedBox(height: 4),
                IncidentReportLabels(report: report, status: statusFor(report)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
