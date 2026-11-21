import '../../auth/models/user_role.dart';
import '../../incident_report/models/incident_report.dart';
import '../models/technician_task.dart';

typedef ReportOwner = ({UserRole role, String id});

ReportOwner demoReportOwner(UserRole role, String loginId) {
  final id = loginId.trim().toLowerCase();
  const schoolDomain = '@ut.edu.vn';
  return (
    role: role,
    id: id.endsWith(schoolDomain) && id.length > schoolDomain.length
        ? id.substring(0, id.length - schoolDomain.length)
        : id,
  );
}

/// Shares report history and work status across demo logins.
class DemoIncidentQueue {
  final _reports = <ReportOwner, Map<IncidentReport, TechnicianTask?>>{};
  var _nextId = 1;

  int get nextId => _nextId;

  Iterable<TechnicianTask> get tasks =>
      _reports.values.expand((reports) => reports.values.nonNulls);

  List<IncidentReport> reportsFor(ReportOwner owner) {
    final reports = _reports[owner];
    if (reports == null) return [];
    final newestFirst = reports.entries.toList().reversed;
    return [
      for (final entry in newestFirst)
        if (entry.value?.status == TaskStatus.inProgress) entry.key,
      for (final entry in newestFirst)
        if (entry.value?.status != TaskStatus.inProgress) entry.key,
    ];
  }

  void submit(ReportOwner owner, IncidentReport report, String reporter) {
    final urgent = owner.role == UserRole.teacher && report.needsSupport;
    final submitted = report.submittedAt;
    final reports = _reports.putIfAbsent(owner, () => {});
    reports[report] = TechnicianTask(
      title: report.title,
      location: report.asset,
      description: report.description,
      evidence: report.photos,
      reporter: report.course.isEmpty
          ? reporter
          : '$reporter · ${report.course}',
      scheduledAt: urgent
          ? DateTime(submitted.year, submitted.month, submitted.day, 23, 59)
          : null,
      isUrgent: urgent,
    );
    _nextId++;
  }

  ({IncidentStatus status, DateTime? updatedAt}) progressFor(
    ReportOwner owner,
    IncidentReport report,
  ) {
    final task = _reports[owner]?[report];
    return (
      status: switch (task?.status) {
        TaskStatus.pending => IncidentStatus.pending,
        TaskStatus.inProgress => IncidentStatus.inProgress,
        TaskStatus.completed => IncidentStatus.completed,
        null => IncidentStatus.cancelled,
      },
      updatedAt: task?.statusUpdatedAt,
    );
  }

  void cancel(ReportOwner owner, IncidentReport report) {
    final reports = _reports[owner];
    if (reports?[report]?.status == TaskStatus.pending) {
      reports![report] = null;
    }
  }
}
