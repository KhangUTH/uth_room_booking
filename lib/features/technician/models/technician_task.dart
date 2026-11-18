import 'dart:typed_data';

class TechnicianTaskUnavailable implements Exception {
  const TechnicianTaskUnavailable();
}

enum TaskStatus {
  pending('Chờ nhận'),
  inProgress('Đang xử lý'),
  completed('Đã hoàn tất');

  const TaskStatus(this.label);
  final String label;
}

class TechnicianTask {
  final String title;
  final String location;
  final String description;
  final String reporter;
  final DateTime? scheduledAt;
  final bool isUrgent;
  final bool isMaintenance;
  final List<Uint8List> evidence;
  final Future<List<Uint8List>> Function()? loadEvidence;
  final Future<TaskStatus> Function(TaskStatus)? onAdvance;
  bool _advancing = false;
  TaskStatus _status;
  DateTime? _statusUpdatedAt;

  TaskStatus get status => _status;
  DateTime? get statusUpdatedAt => _statusUpdatedAt;

  TechnicianTask({
    required this.title,
    required this.location,
    required this.description,
    required this.reporter,
    required this.scheduledAt,
    this.isUrgent = false,
    this.isMaintenance = false,
    this.evidence = const [],
    this.loadEvidence,
    this.onAdvance,
    this._status = TaskStatus.pending,
  });

  Future<bool> advance() async {
    if (_advancing) return false;
    final next = switch (_status) {
      TaskStatus.pending => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.completed,
      TaskStatus.completed => null,
    };
    if (next == null) return false;
    _advancing = true;
    try {
      final persist = onAdvance;
      _status = persist == null ? next : await persist(_status);
      _statusUpdatedAt = DateTime.now();
      return true;
    } finally {
      _advancing = false;
    }
  }
}

// Dữ liệu demo, tạo theo ngày hiện tại để có thể thử bộ lọc lịch.
List<TechnicianTask> createSampleTechnicianTasks() {
  final now = DateTime.now();
  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime(now.year, now.month, now.day + day, hour, minute);
  return [
    TechnicianTask(
      title: 'Máy chiếu - H301',
      location: 'Dãy H, Tầng 3',
      description: 'Không lên hình',
      reporter: 'SV báo cáo',
      scheduledAt: at(0, 8),
      isUrgent: true,
      status: TaskStatus.inProgress,
    ),
    TechnicianTask(
      title: 'Phòng máy 5',
      location: 'Dãy H, Tầng 1',
      description: 'Kiểm tra định kỳ',
      reporter: 'Lịch bảo trì',
      scheduledAt: at(0, 10, 30),
      isMaintenance: true,
      status: TaskStatus.inProgress,
    ),
    TechnicianTask(
      title: 'Chuột - Phòng máy 3',
      location: 'Dãy H, Tầng 1',
      description: 'Chuột không phản hồi',
      reporter: 'GV báo cáo',
      scheduledAt: at(0, 14),
      isUrgent: true,
      status: TaskStatus.inProgress,
    ),
    TechnicianTask(
      title: 'Máy chiếu - H203',
      location: 'Dãy H, Tầng 2',
      description: 'Không lên nét',
      reporter: 'SV báo cáo',
      scheduledAt: at(0, 15),
    ),
    TechnicianTask(
      title: 'Loa - H105',
      location: 'Dãy H, Tầng 1',
      description: 'Không lên tiếng',
      reporter: 'GV báo cáo',
      scheduledAt: at(0, 16),
    ),
    TechnicianTask(
      title: 'Máy chiếu - H302',
      location: 'Dãy H, Tầng 3',
      description: 'Màn hình nhấp nháy',
      reporter: 'SV báo cáo',
      scheduledAt: at(0, 17),
      isUrgent: true,
    ),
    TechnicianTask(
      title: 'Điều hòa - H201',
      location: 'Dãy H, Tầng 2',
      description: 'Vệ sinh bộ lọc',
      reporter: 'Lịch bảo trì',
      scheduledAt: at(1, 9),
      isMaintenance: true,
      status: TaskStatus.inProgress,
    ),
    TechnicianTask(
      title: 'Micro - H101',
      location: 'Dãy H, Tầng 1',
      description: 'Đã thay pin và kiểm tra',
      reporter: 'GV báo cáo',
      scheduledAt: at(0, 7),
      status: TaskStatus.completed,
    ),
  ];
}
