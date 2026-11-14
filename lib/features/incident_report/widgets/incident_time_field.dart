import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'incident_report_labels.dart';

const _line = Color(0xFFD6E6E7);

Future<DateTime?> pickIncidentTime(
  BuildContext context,
  DateTime initial,
) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateUtils.dateOnly(DateTime.now()),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null || !context.mounted) return null;

  final selected = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  if (selected.isAfter(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thời gian xảy ra phải là hiện tại hoặc trước đó.'),
      ),
    );
    return null;
  }
  return selected;
}

class IncidentTimeField extends StatelessWidget {
  const IncidentTimeField({
    super.key,
    required this.value,
    required this.onTap,
  });

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const IncidentFieldTitle('Thời gian xảy ra'),
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: const BorderSide(color: _line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(formatIncidentDateTime(context, value))),
            const Icon(Icons.calendar_today_outlined, size: 16),
          ],
        ),
      ),
    ],
  );
}
