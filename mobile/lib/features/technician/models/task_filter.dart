import 'technician_task.dart';

enum TaskFilter {
  pending('Chờ nhận'),
  active('Đang sửa'),
  completed('Đã hoàn tất'),
  urgent('Gấp');

  const TaskFilter(this.label);
  final String label;

  bool matches(TechnicianTask task) => switch (this) {
    pending => task.status == TaskStatus.pending,
    active => task.status == TaskStatus.inProgress,
    completed => task.status == TaskStatus.completed,
    urgent => task.isUrgent && task.status != TaskStatus.completed,
  };
}
