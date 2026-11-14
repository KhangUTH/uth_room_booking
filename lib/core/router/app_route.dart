import 'dart:typed_data';

import '../../features/auth/models/user_role.dart';
import '../../features/technician/models/technician_task.dart';
import '../../features/notifications/models/app_notice.dart';

abstract final class AppRoute {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const rooms = '/rooms';
  static const equipment = '/equipment';
  static const notifications = '/notifications';
  static const technicianTask = '/technician/task';
  static const taskEvidence = '/technician/task/evidence';
}

typedef HomeRouteArgs = ({String name, String id, UserRole role});

typedef NotificationsRouteArgs = ({
  Set<int> read,
  Set<int> saved,
  List<AppNotice> notices,
});

typedef TechnicianTaskRouteArgs = ({
  TechnicianTask task,
  void Function() onChanged,
});

typedef TaskEvidenceRouteArgs = Uint8List;
