import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/incident_report.dart';

const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class IncidentReportProgress extends StatelessWidget {
  const IncidentReportProgress({super.key, required this.status});

  final IncidentStatus status;
  static const _steps = [
    IncidentStatus.pending,
    IncidentStatus.inProgress,
    IncidentStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps.indexOf(status);
    return Stack(
      children: [
        const Positioned(
          left: 44,
          right: 44,
          top: 12,
          child: Divider(height: 1, thickness: 1, color: _line),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, step) in _steps.indexed)
              Expanded(
                child: Column(
                  spacing: 5,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: index <= currentStep
                          ? AppColors.primary
                          : const Color(0xFFF2F7F7),
                      foregroundColor: index <= currentStep
                          ? Colors.white
                          : _muted,
                      child: Icon(
                        index < currentStep ? Icons.check : step.icon,
                        size: 14,
                      ),
                    ),
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: index <= currentStep
                            ? AppColors.primary
                            : _muted,
                        fontSize: 11,
                        fontWeight: step == status
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
