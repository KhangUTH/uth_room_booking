enum TaskStatus {
  pending('Chờ nhận'),
  accepted('Đã nhận'),
  inProgress('Đang xử lý'),
  completed('Đã xong');

  const TaskStatus(this.label);
  final String label;
}

enum TaskPriority {
  urgent('Khẩn'),
  medium('Trung bình'),
  low('Thấp');

  const TaskPriority(this.label);
  final String label;
}

class TechnicianTask {
  final String title;
  final String location;
  final String description;
  final String reporter;
  final DateTime scheduledAt;
  final TaskPriority priority;
  final bool isMaintenance;
  TaskStatus status;

  TechnicianTask({
    required this.title,
    required this.location,
    required this.description,
    required this.reporter,
    required this.scheduledAt,
    required this.priority,
    this.isMaintenance = false,
    this.status = TaskStatus.pending,
  });
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
      priority: TaskPriority.urgent,
      status: TaskStatus.inProgress,
    ),
    TechnicianTask(
      title: 'Phòng máy 5',
      location: 'Dãy H, Tầng 1',
      description: 'Kiểm tra định kỳ',
      reporter: 'Lịch bảo trì',
      scheduledAt: at(0, 10, 30),
      priority: TaskPriority.medium,
      isMaintenance: true,
      status: TaskStatus.accepted,
    ),
    TechnicianTask(
      title: 'Chuột - Phòng máy 3',
      location: 'Dãy H, Tầng 1',
      description: 'Chuột không phản hồi',
      reporter: 'GV báo cáo',
      scheduledAt: at(0, 14),
      priority: TaskPriority.urgent,
      status: TaskStatus.accepted,
    ),
    TechnicianTask(
      title: 'Máy chiếu - H203',
      location: 'Dãy H, Tầng 2',
      description: 'Không lên nét',
      reporter: 'SV báo cáo',
      scheduledAt: at(0, 15),
      priority: TaskPriority.medium,
    ),
    TechnicianTask(
      title: 'Loa - H105',
      location: 'Dãy H, Tầng 1',
      description: 'Không lên tiếng',
      reporter: 'GV báo cáo',
      scheduledAt: at(0, 16),
      priority: TaskPriority.low,
    ),
    TechnicianTask(
      title: 'Máy chiếu - H302',
      location: 'Dãy H, Tầng 3',
      description: 'Màn hình nhấp nháy',
      reporter: 'SV báo cáo',
      scheduledAt: at(0, 17),
      priority: TaskPriority.urgent,
    ),
    TechnicianTask(
      title: 'Điều hòa - H201',
      location: 'Dãy H, Tầng 2',
      description: 'Vệ sinh bộ lọc',
      reporter: 'Lịch bảo trì',
      scheduledAt: at(1, 9),
      priority: TaskPriority.low,
      isMaintenance: true,
      status: TaskStatus.accepted,
    ),
    TechnicianTask(
      title: 'Micro - H101',
      location: 'Dãy H, Tầng 1',
      description: 'Đã thay pin và kiểm tra',
      reporter: 'GV báo cáo',
      scheduledAt: at(0, 7),
      priority: TaskPriority.low,
      status: TaskStatus.completed,
    ),
  ];
}
