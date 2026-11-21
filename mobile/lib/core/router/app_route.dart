import 'dart:typed_data';

import '../../features/auth/models/user_role.dart';
import '../../features/booking/data/booking_store.dart';
import '../../features/incident_report/data/incident_report_store.dart';
import '../../features/notifications/data/notice_store.dart';
import '../../features/notifications/models/app_notice.dart';
import '../../features/technician/models/technician_task.dart';
import '../../features/technician/data/technician_incident_store.dart';

abstract final class AppRoute {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const rooms = '/rooms';
  static const equipment = '/equipment';
  static const notifications = '/notifications';
  static const appPermissions = '/profile/permissions';
  static const technicianTask = '/technician/task';
  static const taskEvidence = '/technician/task/evidence';
}

typedef HomeRouteArgs = ({
  String name,
  String id,
  UserRole role,
  String? faculty,
});

typedef NotificationsRouteArgs = ({
  Set<int> read,
  Set<int> saved,
  List<AppNotice> notices,
  NoticeStore? store,
  BookingStore? bookingStore,
  IncidentReportStore? incidentStore,
  TechnicianIncidentStore? technicianStore,
  int? initialNoticeId,
});

typedef TechnicianTaskRouteArgs = ({
  TechnicianTask task,
  void Function() onChanged,
});

typedef TaskEvidenceRouteArgs = Uint8List;
