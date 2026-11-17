import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';
import '../models/device.dart';

final sampleDevices = List<Device>.unmodifiable(
  sampleBookingEquipment.map(
    (asset) => Device(
      asset.name,
      asset.slots.contains(SlotStatus.maintenance) ? 'Bảo trì' : 'Sẵn sàng',
    ),
  ),
);
