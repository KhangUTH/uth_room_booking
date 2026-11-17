import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../controllers/booking_controller.dart';
import '../data/sample_booking_data.dart';
import '../models/booking.dart';
import '../widgets/booking_confirmation_sheet.dart';
import '../widgets/booking_calendar.dart';
import '../widgets/booking_asset_card.dart';
import '../widgets/booking_hint.dart';
import '../widgets/booking_slot_picker.dart';
import '../widgets/booking_category_tabs.dart';
import '../widgets/booking_history_card.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _muted = Color(0xFF526E74);
const _headingColor = Color(0xFF303638);

enum BookingCategory { rooms, equipment, mine }

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key, required this.bookings, this.categoryRequest});

  final BookingController bookings;
  final ({BookingCategory category, int sequence})? categoryRequest;

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  BookingController get _bookings => widget.bookings;
  DateTime get _today => _bookings.today;

  bool get _isMine => _category == BookingCategory.mine;
  late DateTime _date = _today;
  late BookingCategory _category =
      widget.categoryRequest?.category ?? BookingCategory.rooms;
  bool _showAllBookingDates = false;
  int _slotIndex = 0;

  @override
  void didUpdateWidget(covariant ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final request = widget.categoryRequest;
    if (request != null && request != oldWidget.categoryRequest) {
      _category = request.category;
    }
  }

  void _chooseDate(DateTime date) => setState(() {
    _date = date;
    _showAllBookingDates = false;
  });

  List<BookingAsset> get _visibleAssets => _category == BookingCategory.rooms
      ? sampleBookingRooms
      : sampleBookingEquipment;

  Future<void> _openBooking(BookingAsset asset) async {
    final slot = (date: _date, asset: asset.name, index: _slotIndex);
    final selection = await showModalBottomSheet<BookingSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 720),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (_) => BookingConfirmationSheet(
        slot: slot,
        asset: asset,
        role: _bookings.role,
      ),
    );
    if (!mounted || selection == null) return;
    final registered = _bookings.register(
      slot,
      asset,
      selection.section,
      studentCount: selection.studentCount,
    );
    if (registered) setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            registered
                ? 'Đã tạo đăng ký mẫu. Trạng thái: Chờ duyệt.'
                : 'Ca này hiện không thể đăng ký.',
          ),
        ),
      );
  }

  int _availableCount(List<BookingAsset> assets, int index) =>
      _date.isBefore(_today)
      ? 0
      : assets
            .where(
              (asset) =>
                  _bookings.statusFor(_date, asset, index) == SlotStatus.free,
            )
            .length;

  @override
  Widget build(BuildContext context) {
    final assets = _isMine ? const <BookingAsset>[] : _visibleAssets;
    final bookingIndices = _isMine
        ? _bookings.indicesFor(_showAllBookingDates ? null : _date)
        : const <int>[];
    return Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 28,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.appBar,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
        ),
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            BookingCalendar(
              date: _date,
              hasSchedule: _bookings.hasSchedule,
              onDateChanged: _chooseDate,
            ),
            const SizedBox(height: 12),
            _buildCategories(),
            if (_isMine) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: const Text('Tất cả ngày'),
                  selected: _showAllBookingDates,
                  onSelected: (value) =>
                      setState(() => _showAllBookingDates = value),
                ),
              ),
              if (bookingIndices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _showAllBookingDates
                          ? 'Bạn chưa có đăng ký nào'
                          : 'Bạn chưa có đăng ký trong ngày này',
                    ),
                  ),
                ),
              for (final index in bookingIndices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BookingHistoryCard(
                    booking: _bookings.bookingAt(index),
                    onCancel: _bookings.role == UserRole.technician
                        ? null
                        : () => _cancelBooking(index),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 14),
              BookingSlotPicker(
                selectedIndex: _slotIndex,
                availableCount: (index) => _availableCount(assets, index),
                onSelected: (index) => setState(() => _slotIndex = index),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _category == BookingCategory.rooms
                          ? 'Danh sách phòng'
                          : 'Danh sách thiết bị',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _headingColor,
                      ),
                    ),
                  ),
                  Text(
                    '${_availableCount(assets, _slotIndex)} trống · Ca ${_slotIndex + 1}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final asset in assets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BookingAssetCard(
                    asset: asset,
                    status: _bookings.statusFor(_date, asset, _slotIndex),
                    past: _date.isBefore(_today),
                    onTap: () => _openBooking(asset),
                  ),
                ),
              if (_availableCount(assets, _slotIndex) > 0)
                BookingHint(
                  label: _category == BookingCategory.rooms
                      ? 'Chạm một phòng trống để đặt'
                      : 'Chạm một thiết bị trống để đăng ký sử dụng',
                ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategories() => BookingCategoryTabs(
    options: const [
      (BookingCategory.rooms, 'Phòng máy'),
      (BookingCategory.equipment, 'Thiết bị'),
      (BookingCategory.mine, 'Của tôi'),
    ],
    selected: _category,
    onChanged: (category) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() => _category = category);
    },
  );

  Future<void> _cancelBooking(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch đăng ký?'),
        content: const Text('Ca này sẽ được trả lại danh sách ca trống.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lịch'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_bookings.cancel(index)) setState(() {});
  }
}
