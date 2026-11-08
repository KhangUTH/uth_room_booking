import 'technician_task.dart';

enum TaskFilter {
  pending('Chờ nhận'),
  active('Đang sửa'),
  completed('Đã xong'),
  overdue('Quá hạn');

  const TaskFilter(this.label);
  final String label;

  bool matches(TechnicianTask task, DateTime now) => switch (this) {
    pending => task.status == TaskStatus.pending,
    active =>
      task.status == TaskStatus.accepted ||
          task.status == TaskStatus.inProgress,
    completed => task.status == TaskStatus.completed,
    overdue =>
      task.status != TaskStatus.completed && task.scheduledAt.isBefore(now),
  };
}
