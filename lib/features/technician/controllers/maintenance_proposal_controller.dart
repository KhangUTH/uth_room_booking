import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';
import '../models/maintenance_proposal.dart';

class MaintenanceProposalController {
  MaintenanceProposalController(DateTime today)
    : approvedBookings = createSampleUsageSchedule(today),
      _proposals = [
        MaintenanceProposal(
          asset: sampleBookingRooms[1],
          reason: 'Kiểm tra định kỳ máy trạm.',
          status: MaintenanceStatus.approved,
        ),
        MaintenanceProposal(
          asset: sampleBookingEquipment.first,
          reason: 'Kiểm tra nguồn cấp máy chiếu.',
          status: MaintenanceStatus.rejected,
        ),
      ];

  final List<Booking> approvedBookings;
  final List<MaintenanceProposal> _proposals;

  List<MaintenanceProposal> get proposals => List.unmodifiable(_proposals);

  bool conflictsWithBooking(BookingSlot slot) =>
      approvedBookings.any((booking) => booking.slot == slot);

  void submit(MaintenanceProposal proposal) => _proposals.insert(0, proposal);

  void cancel(MaintenanceProposal proposal) {
    final index = _proposals.indexOf(proposal);
    if (index == -1 || proposal.status != MaintenanceStatus.pending) return;
    _proposals[index] = MaintenanceProposal(
      asset: proposal.asset,
      reason: proposal.reason,
      schedule: proposal.schedule,
      status: MaintenanceStatus.cancelled,
    );
  }
}
