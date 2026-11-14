import 'package:flutter/material.dart';

import '../models/incident_report.dart';

const _muted = Color(0xFF526E74);

class IncidentReportLabels extends StatelessWidget {
  const IncidentReportLabels({
    super.key,
    required this.report,
    required this.status,
  });

  final IncidentReport report;
  final IncidentStatus status;
  bool get cancelled => status == IncidentStatus.cancelled;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      _statusLabel(),
      if (report.needsSupport)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cancelled
                ? const Color(0xFFF2EAEA)
                : const Color(0xFFFCE9ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            cancelled ? 'Đã yêu cầu hỗ trợ ngay' : 'Cần hỗ trợ ngay',
            style: TextStyle(
              color: cancelled ? _muted : const Color(0xFF9A2440),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );

  Widget _statusLabel() {
    final (background, foreground) = switch (status) {
      IncidentStatus.pending => (
        const Color(0xFFFFF0CC),
        const Color(0xFF785100),
      ),
      IncidentStatus.cancelled => (const Color(0xFFF2EAEA), _muted),
      _ => (const Color(0xFFDCEFEF), const Color(0xFF006D72)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class IncidentFieldTitle extends StatelessWidget {
  const IncidentFieldTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

String formatIncidentDateTime(BuildContext context, DateTime date) {
  final localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
    alwaysUse24HourFormat: true,
  );
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$time · $day/$month/${date.year}';
}
