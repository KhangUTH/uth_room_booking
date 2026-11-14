import 'package:flutter/material.dart';

import '../../../shared/widgets/pill_tabs.dart';
import '../../auth/models/user_role.dart';
import '../../technician/data/demo_incident_queue.dart';
import '../models/incident_report.dart';
import '../widgets/incident_report_details_sheet.dart';
import '../widgets/incident_report_form.dart';
import '../widgets/incident_report_history.dart';

class IncidentReportView extends StatefulWidget {
  const IncidentReportView({
    super.key,
    required this.name,
    required this.id,
    required this.role,
    required this.queue,
  });

  final String name;
  final String id;
  final UserRole role;
  final DemoIncidentQueue queue;

  @override
  State<IncidentReportView> createState() => _IncidentReportViewState();
}

class _IncidentReportViewState extends State<IncidentReportView> {
  ReportOwner get _owner => demoReportOwner(widget.role, widget.id);
  late bool _showHistory = widget.queue.reportsFor(_owner).isNotEmpty;

  void _submit(IncidentReport report) {
    setState(() {
      widget.queue.submit(_owner, report, widget.name);
      _showHistory = true;
    });
    _showReport(report);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: PillTabs<bool>(
          options: const {false: 'Tạo báo cáo', true: 'Báo cáo của tôi'},
          selected: _showHistory,
          onSelected: (showHistory) {
            if (_showHistory == showHistory) return;
            FocusScope.of(context).unfocus();
            setState(() => _showHistory = showHistory);
          },
        ),
      ),
      Expanded(
        child: IndexedStack(
          index: _showHistory ? 1 : 0,
          children: [
            IncidentReportForm(
              name: widget.name,
              id: widget.id,
              role: widget.role,
              nextReportId: () => widget.queue.nextId,
              onSubmitted: _submit,
            ),
            IncidentReportHistory(
              reports: widget.queue.reportsFor(_owner),
              statusFor: (report) =>
                  widget.queue.progressFor(_owner, report).status,
              onOpen: _showReport,
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _showReport(IncidentReport report) async {
    final progress = widget.queue.progressFor(_owner, report);
    final shouldCancel = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => IncidentReportDetailsSheet(
        report: report,
        status: progress.status,
        updatedAt: progress.updatedAt,
      ),
    );
    if (shouldCancel == true && mounted) {
      setState(() => widget.queue.cancel(_owner, report));
    }
  }
}
