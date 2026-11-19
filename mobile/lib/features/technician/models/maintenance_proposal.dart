import '../../booking/models/booking.dart';

enum MaintenanceStatus {
  pending('Chờ duyệt'),
  approved('Đã duyệt'),
  rejected('Từ chối'),
  cancelled('Đã hủy');

  const MaintenanceStatus(this.label);
  final String label;
}

class MaintenanceProposal {
  const MaintenanceProposal({
    required this.asset,
    required this.reason,
    this.schedule,
    this.status = MaintenanceStatus.pending,
  });

  final BookingAsset asset;
  final String reason;
  final BookingSlot? schedule;
  final MaintenanceStatus status;
}
