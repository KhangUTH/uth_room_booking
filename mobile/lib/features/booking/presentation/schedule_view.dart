import 'dart:async';

import 'package:flutter/material.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

import '../../auth/models/user_role.dart';
import '../controllers/booking_controller.dart';
import '../data/asset_catalog.dart';
import '../data/sample_booking_data.dart';
import '../models/booking.dart';
import '../widgets/booking_asset_list.dart';
import '../widgets/booking_calendar.dart';
import '../widgets/booking_category_tabs.dart';
import '../widgets/booking_action_dialogs.dart';
import '../widgets/booking_hint.dart';
import '../widgets/my_bookings_section.dart';

enum BookingCategory { rooms, equipment, mine }

class ScheduleView extends StatefulWidget {
  const ScheduleView({
    super.key,
    required this.bookings,
    this.categoryRequest,
    this.catalog,
    this.refreshCatalog,
    this.active = true,
    this.noticeAccountId,
  });

  final BookingController bookings;
  final ({BookingCategory category, int sequence})? categoryRequest;
  final AssetCatalog? catalog;
  final Future<AssetCatalog?> Function()? refreshCatalog;
  final bool active;
  final String? noticeAccountId;

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
  bool _busy = false;
  bool _refreshing = false;
  bool _saving = false;
  bool _historyFailed = false;
  bool _slotsFailed = false;
  DateTime? _slotsDay;
  int _request = 0;
  bool get _loadFailed => _isMine ? _historyFailed : _slotsFailed;
  bool get _hasVisibleData =>
      _bookings.store == null ||
      (_isMine ? _bookings.hasHistory : _slotsDay == _date);
  ({String message, bool failed})? _feedback;
  Timer? _feedbackTimer;
  Timer? _refreshTimer;
  bool _checkingNotice = false;

  @override
  void initState() {
    super.initState();
    _updateRefreshTimer();
    if (widget.active && _bookings.store != null) _refresh();
    if (widget.active) _scheduleUsageNotice();
  }

  void _scheduleUsageNotice() {
    final account = widget.noticeAccountId;
    final role = _bookings.role;
    if (account == null || role == UserRole.technician || _checkingNotice) {
      return;
    }
    _checkingNotice = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        await BookingUsageNotice.showOnce(
          context,
          role: role.name,
          account: account,
          isActive: () => widget.active,
        );
      } finally {
        _checkingNotice = false;
      }
    });
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateRefreshTimer() {
    _refreshTimer?.cancel();
    if (!widget.active || _bookings.store == null) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_refreshing &&
          !_saving &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          ModalRoute.isCurrentOf(context) == true) {
        unawaited(_refresh(silent: _hasVisibleData));
      }
    });
  }

  Future<void> _refresh({
    bool reloadCatalog = false,
    bool silent = false,
  }) async {
    final store = _bookings.store;
    if (store == null || widget.catalog == null) return;
    final request = ++_request;
    _refreshing = true;
    final day = _date;
    setState(() {
      _busy = !silent;
    });
    Future<void> load(
      Future<void> Function() operation,
      VoidCallback onSuccess,
      VoidCallback onFailure,
    ) async {
      try {
        await operation();
        if (mounted && request == _request) setState(onSuccess);
      } catch (_) {
        if (mounted && request == _request) setState(onFailure);
      }
    }

    await Future.wait([
      load(
        _bookings.refreshHistory,
        () => _historyFailed = false,
        () => _historyFailed = true,
      ),
      load(
        () async {
          if (reloadCatalog) await widget.refreshCatalog?.call();
          if (!mounted || request != _request) return;
          final slots = await store.busySlots(day);
          if (!mounted || request != _request) return;
          _bookings.busy = slots;
          _slotsDay = day;
        },
        () => _slotsFailed = false,
        () => _slotsFailed = true,
      ),
    ]);
    if (mounted && request == _request) {
      _refreshing = false;
      if (_busy) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active ||
        widget.bookings != oldWidget.bookings) {
      _updateRefreshTimer();
    }
    if (widget.active && !oldWidget.active) _scheduleUsageNotice();
    final request = widget.categoryRequest;
    final changedCategory =
        request != null && request != oldWidget.categoryRequest;
    if (changedCategory) {
      _category = request.category;
      _clearFeedback();
    }
    if (widget.active &&
        !oldWidget.active &&
        _bookings.store != null &&
        !_saving) {
      _refresh();
    }
  }

  void _chooseDate(DateTime date) {
    if (_saving || date == _date) return;
    setState(() {
      _date = date;
      _showAllBookingDates = false;
      _clearFeedback();
    });
    if (_bookings.store != null) _refresh();
  }

  List<BookingAsset> get _visibleAssets {
    final catalog = widget.catalog;
    if (_category == BookingCategory.equipment) {
      return catalog?.equipment ?? sampleBookingEquipment;
    }
    final rooms = catalog?.rooms ?? sampleBookingRooms;
    if (_bookings.role != UserRole.teacher) return rooms;
    final blockedRooms =
        catalog?.roomsUnavailableToTeachers ?? {sampleLibraryRoomName};
    return rooms
        .where((room) => !blockedRooms.contains(room.bookingKey))
        .toList();
  }

  Future<void> _openBooking(BookingAsset asset) async {
    if (_busy || _saving || _loadFailed) return;
    if (asset.capacity > 0 &&
        _bookings.hasStudentRoomBooking(_date, _slotIndex)) {
      return;
    }
    final slot = (date: _date, asset: asset.bookingKey, index: _slotIndex);
    final live = _bookings.store != null;
    var courses = sampleTeachingCourses;
    final liveCourses = _bookings.liveCoursesFor(asset);
    if (liveCourses != null) {
      setState(() => _saving = true);
      try {
        courses = await liveCourses;
      } catch (_) {
        if (mounted) _message('Không tải được lớp học phần. Vui lòng thử lại.');
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      if (!mounted) return;
      if (courses.isEmpty) {
        _message('Tài khoản chưa được phân công lớp học phần.');
        return;
      }
    }
    final selection = await confirmBooking(
      context,
      slot: slot,
      asset: asset,
      role: _bookings.role,
      courses: courses,
    );
    if (!mounted || selection == null) return;
    await _save(
      () => _bookings.submit(
        slot,
        asset,
        section: selection.section,
        studentCount: selection.studentCount,
      ),
      live
          ? 'Đã gửi đăng ký. Trạng thái: Chờ duyệt.'
          : 'Đã tạo đăng ký mẫu. Trạng thái: Chờ duyệt.',
      live
          ? 'Không thể đăng ký. Ca có thể đã được đặt hoặc đã bắt đầu.'
          : 'Ca này hiện không thể đăng ký.',
    );
  }

  void _clearFeedback() {
    _feedbackTimer?.cancel();
    _feedback = null;
  }

  void _message(String message, {bool failed = true}) {
    _feedbackTimer?.cancel();
    setState(() => _feedback = (message: message, failed: failed));
    _feedbackTimer = Timer(
      Duration(seconds: failed ? 4 : 2),
      () => setState(_clearFeedback),
    );
  }

  Future<void> _save(
    Future<bool> Function() operation,
    String success,
    String failure,
  ) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _clearFeedback();
    });
    try {
      final saved = await operation();
      if (mounted) _message(saved ? success : failure, failed: !saved);
    } catch (_) {
      if (mounted) _message(failure);
    } finally {
      if (mounted) {
        if (_bookings.store != null) await _refresh();
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  bool _hasStarted(int index) =>
      _bookings.store?.hasStarted(_date, index) ?? _date.isBefore(_today);

  int _availableCount(List<BookingAsset> assets, int index) =>
      _hasStarted(index) || _roomSlotTaken(index)
      ? 0
      : assets
            .where(
              (asset) =>
                  _bookings.statusFor(_date, asset, index) == SlotStatus.free,
            )
            .length;

  bool _roomSlotTaken(int index) =>
      _category == BookingCategory.rooms &&
      _bookings.hasStudentRoomBooking(_date, index);

  @override
  Widget build(BuildContext context) {
    final assets = _isMine ? const <BookingAsset>[] : _visibleAssets;
    final bookingIndices = _isMine
        ? _bookings.indicesFor(
            _showAllBookingDates ? null : _date,
            cancelledLast: true,
          )
        : const <int>[];
    final content = Stack(
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
        _refreshable(
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            children: [
              BookingCalendar(
                date: _date,
                today: _today,
                hasSchedule: _bookings.hasSchedule,
                onDateChanged: _chooseDate,
              ),
              const SizedBox(height: 12),
              _buildCategories(),
              if (_busy || _saving)
                const LinearProgressIndicator()
              else if (_loadFailed)
                TextButton(
                  onPressed: _refresh,
                  child: Text(
                    _hasVisibleData
                        ? 'Đang hiển thị dữ liệu lần tải gần nhất. Thử lại'
                        : 'Không tải được lịch. Thử lại',
                  ),
                ),
              if (_hasVisibleData && _isMine)
                ...buildMyBookingItems(
                  indices: bookingIndices,
                  bookingAt: _bookings.bookingAt,
                  showAllDates: _showAllBookingDates,
                  onShowAllDatesChanged: (value) =>
                      setState(() => _showAllBookingDates = value),
                  onCancel: _bookings.role == UserRole.technician
                      ? null
                      : _cancelBooking,
                )
              else if (_hasVisibleData)
                BookingAssetList(
                  assets: assets,
                  isRoom: _category == BookingCategory.rooms,
                  slotIndex: _slotIndex,
                  past: _hasStarted(_slotIndex),
                  roomSlotTaken: _roomSlotTaken(_slotIndex),
                  availableCount: (index) => _availableCount(assets, index),
                  statusFor: (asset) =>
                      _bookings.statusFor(_date, asset, _slotIndex),
                  onSlotSelected: (index) => setState(() => _slotIndex = index),
                  onAssetSelected: _openBooking,
                ),
            ],
          ),
        ),
      ],
    );
    final feedback = _feedback;
    return Column(
      children: [
        Expanded(child: content),
        if (feedback != null)
          BookingFeedback(message: feedback.message, failed: feedback.failed),
      ],
    );
  }

  Widget _refreshable(Widget child) => _bookings.store == null
      ? child
      : RefreshIndicator(
          onRefresh: () async {
            if (!_saving) await _refresh(reloadCatalog: true);
          },
          child: child,
        );

  Widget _buildCategories() => BookingCategoryTabs(
    options: const [
      (BookingCategory.rooms, 'Phòng máy'),
      (BookingCategory.equipment, 'Thiết bị'),
      (BookingCategory.mine, 'Của tôi'),
    ],
    selected: _category,
    onChanged: (category) {
      setState(() {
        _category = category;
        _clearFeedback();
      });
    },
  );

  Future<void> _cancelBooking(int index) async {
    if (_saving) return;
    final bookingId = _bookings.savedBookingId(index);
    final booking = _bookings.bookingAt(index);
    final confirmed = await confirmBookingCancellation(context);
    if (confirmed != true || !mounted) return;
    await _save(
      () => _bookings.cancelBooking(booking, bookingId),
      'Đã hủy đăng ký.',
      'Không thể hủy. Đơn có thể đã đổi trạng thái.',
    );
  }
}
