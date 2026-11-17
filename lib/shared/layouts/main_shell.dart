import "package:flutter/material.dart";
import "package:uth_room_booking/shared/layouts/bottom_navigation_bar.dart";
import "package:uth_room_booking/shared/layouts/header.dart";
import "package:uth_room_booking/features/room/data/sample_rooms.dart";
import 'package:uth_room_booking/core/router/app_route.dart';

import '../../features/auth/models/user_role.dart';
import '../../features/booking/models/booking.dart';
import '../../features/booking/controllers/booking_controller.dart';
import '../../features/booking/data/sample_booking_data.dart';
import '../../features/booking/widgets/booking_history_card.dart';
import '../../features/technician/controllers/maintenance_proposal_controller.dart';
import '../../features/technician/presentation/maintenance_proposals_page.dart';
import '../../features/technician/models/task_filter.dart';
import '../../features/technician/data/demo_incident_queue.dart';
import '../../features/technician/models/technician_task.dart';
import '../../features/technician/presentation/technician_assets_page.dart';
import '../../features/technician/presentation/technician_schedule_page.dart';
import '../../features/home/presentation/home_dashboard.dart';
import '../../features/incident_report/presentation/incident_report_view.dart';
import '../../features/notifications/data/sample_notices.dart';
import '../../features/notifications/models/app_notice.dart';
import '../../features/profile/presentation/profile_view.dart';
import '../../features/booking/presentation/schedule_view.dart';
import '../../features/technician/presentation/technician_dashboard.dart';
import '../../features/technician/presentation/technician_work_view.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

enum _ShellTab {
  home(
    'Trang chủ',
    Icons.home_outlined,
    activeIcon: Icons.home,
    extendsHeader: true,
  ),
  schedule('Lịch', Icons.calendar_month, extendsHeader: true),
  reports('Báo cáo', Icons.assignment_outlined),
  profile('Cá nhân', Icons.person_outline),
  work('Công việc', Icons.checklist_outlined);

  const _ShellTab(
    this.label,
    this.icon, {
    this.activeIcon,
    this.extendsHeader = false,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final bool extendsHeader;

  BottomNavigationBarItem get item => BottomNavigationBarItem(
    label: label,
    icon: Icon(icon),
    activeIcon: Icon(activeIcon ?? icon),
  );
}

class MainShell extends StatefulWidget {
  final String name;
  final String id;
  final UserRole role;
  final DemoIncidentQueue? incidentQueue;
  final Future<void> Function()? onSignOut;
  final String? accountEmail;
  final String? faculty;
  final ProfileAvatarStorage? avatarStorage;

  const MainShell({
    super.key,
    required this.name,
    required this.id,
    this.role = UserRole.student,
    this.incidentQueue,
    this.onSignOut,
    this.accountEmail,
    this.faculty,
    this.avatarStorage,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  _ShellTab _selectedTab = _ShellTab.home;
  ({BookingCategory category, int sequence})? _bookingCategoryRequest;
  final _readNotices = <int>{};
  final _savedNotices = <int>{};
  ImageProvider? _avatar;
  bool _savingAvatar = false;

  @override
  void initState() {
    super.initState();
    final storage = widget.avatarStorage;
    if (storage != null) _loadAvatar(storage);
  }

  Future<void> _loadAvatar(ProfileAvatarStorage storage) async {
    final bytes = await storage.load();
    if (mounted && bytes != null && _avatar == null) {
      setState(() => _avatar = MemoryImage(bytes));
    }
  }

  Future<void> _changeAvatar() async {
    final storage = widget.avatarStorage;
    if (storage == null || _savingAvatar) return;

    setState(() => _savingAvatar = true);
    try {
      final bytes = await storage.pickAndSave();
      if (mounted && bytes != null) {
        setState(() => _avatar = MemoryImage(bytes));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu ảnh đại diện. Vui lòng thử lại.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  late final _sampleJobs = createSampleTechnicianTasks();
  late final _incidentQueue = widget.incidentQueue ?? DemoIncidentQueue();
  List<TechnicianTask> get _jobs => [..._incidentQueue.tasks, ..._sampleJobs];
  TaskFilter? _workFilter = TaskFilter.pending;
  bool _showWorkSchedule = false;
  bool _showTechnicianAssets = false;
  late final _maintenance = MaintenanceProposalController(
    DateUtils.dateOnly(DateTime.now()),
  );

  bool _showMaintenance = false;
  BookingAsset? _maintenanceAsset;

  bool get _maintenanceVisible =>
      _selectedTab == _ShellTab.home && _showMaintenance;

  void _openMaintenance({BookingAsset? asset}) => setState(() {
    _maintenanceAsset = asset;
    _showMaintenance = true;
  });

  void _closeMaintenance() => setState(() => _showMaintenance = false);

  bool get _assetsVisible =>
      _selectedTab == _ShellTab.home && _showTechnicianAssets;

  void _setTechnicianAssets(bool value) =>
      setState(() => _showTechnicianAssets = value);

  void _refreshWork() => setState(() {
    if (_workFilter == TaskFilter.urgent &&
        !_jobs.any(TaskFilter.urgent.matches)) {
      _workFilter = null;
    }
  });
  void _setWorkSchedule(bool value) =>
      setState(() => _showWorkSchedule = value);

  bool get _isTechnician => widget.role == UserRole.technician;
  List<AppNotice> get _notices =>
      _isTechnician ? technicianNotices : demoNotices;

  void _openWork(TaskFilter? filter) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _workFilter = filter;
      _showWorkSchedule = false;
      _selectedTab = _ShellTab.work;
    });
  }

  Future<void> _openNotifications() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Navigator.of(context).pushNamed<void>(
      AppRoute.notifications,
      arguments: (read: _readNotices, saved: _savedNotices, notices: _notices),
    );
    if (mounted) setState(() {});
  }

  void _selectTab(_ShellTab tab, {BookingCategory? bookingCategory}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedTab = tab;
      if (bookingCategory != null) {
        _bookingCategoryRequest = (
          category: bookingCategory,
          sequence: (_bookingCategoryRequest?.sequence ?? 0) + 1,
        );
      }
      _showTechnicianAssets = false;
      _showMaintenance = false;
    });
  }

  void _backWithinShell() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_maintenanceVisible) {
      _closeMaintenance();
    } else if (_assetsVisible) {
      _setTechnicianAssets(false);
    } else if (_selectedTab == _ShellTab.work && _showWorkSchedule) {
      _setWorkSchedule(false);
    } else {
      _selectTab(_ShellTab.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _isTechnician
        ? const [_ShellTab.home, _ShellTab.work, _ShellTab.profile]
        : const [
            _ShellTab.home,
            _ShellTab.schedule,
            _ShellTab.reports,
            _ShellTab.profile,
          ];
    final selectedIndex = tabs.indexOf(_selectedTab);
    final canGoBackWithinShell =
        _selectedTab != _ShellTab.home || _assetsVisible || _maintenanceVisible;
    return PopScope<void>(
      canPop: !canGoBackWithinShell,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoBackWithinShell) _backWithinShell();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: MyHeader(
          greeting: switch (widget.role) {
            UserRole.student => 'Xin chào, Sinh viên',
            UserRole.teacher => 'Xin chào, Giảng viên',
            UserRole.technician => 'Xin chào, Nhân viên kỹ thuật',
          },
          continueIntoBody:
              _selectedTab.extendsHeader &&
              !_assetsVisible &&
              !_maintenanceVisible,
          avatar: _avatar,
          onAvatarTap:
              _selectedTab == _ShellTab.profile && widget.avatarStorage != null
              ? _changeAvatar
              : null,
          avatarBusy: _selectedTab == _ShellTab.profile && _savingAvatar,
          onBellTap: _openNotifications,
          hasUnreadNotifications: _notices.any(
            (notice) => !_readNotices.contains(notice.id),
          ),
          name: widget.name,
          id: widget.id,
          idLabel: switch (widget.role) {
            UserRole.student => 'MSSV',
            UserRole.teacher => 'MSGV',
            UserRole.technician => 'MSNV',
          },
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: IndexedStack(
            index: selectedIndex,
            children: [
              for (final tab in tabs)
                switch (tab) {
                  _ShellTab.home =>
                    _isTechnician
                        ? _buildTechnicianHome()
                        : _buildHomeContent(),
                  _ShellTab.work =>
                    _showWorkSchedule
                        ? TechnicianSchedulePage(
                            onBack: () => _setWorkSchedule(false),
                          )
                        : TechnicianWorkView(
                            jobs: _jobs,
                            filter: _workFilter,
                            onFilter: (filter) =>
                                setState(() => _workFilter = filter),
                            onChanged: _refreshWork,
                            onSchedule: () => _setWorkSchedule(true),
                          ),
                  _ShellTab.schedule => ScheduleView(
                    bookings: _bookings,
                    categoryRequest: _bookingCategoryRequest,
                  ),
                  _ShellTab.reports => IncidentReportView(
                    name: widget.name,
                    id: widget.id,
                    role: widget.role,
                    queue: _incidentQueue,
                  ),
                  _ShellTab.profile => ProfileView(
                    id: widget.id,
                    role: widget.role,
                    onSignOut: widget.onSignOut,
                    accountEmail: widget.accountEmail,
                    faculty: widget.faculty,
                  ),
                },
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavigationBar(
          items: [for (final tab in tabs) tab.item],
          currentIndex: selectedIndex,
          onTap: (index) => _selectTab(tabs[index]),
        ),
      ),
    );
  }

  Widget _buildTechnicianHome() => IndexedStack(
    index: _showMaintenance
        ? (_showTechnicianAssets ? 2 : 1)
        : (_showTechnicianAssets ? 1 : 0),
    children: [
      TechnicianDashboard(
        jobs: _jobs,
        onWork: _openWork,
        onNotifications: _openNotifications,
        onAssets: () => _setTechnicianAssets(true),
        onMaintenance: _openMaintenance,
      ),
      if (_showTechnicianAssets)
        TechnicianAssetsPage(
          onAsset: (asset) => _openMaintenance(asset: asset),
        ),
      if (_showMaintenance)
        MaintenanceProposalsPage(
          controller: _maintenance,
          initialAsset: _maintenanceAsset,
        ),
    ],
  );

  late final _bookings = _createBookingController();

  BookingController _createBookingController() {
    final today = DateUtils.dateOnly(DateTime.now());
    return BookingController(
      today: today,
      role: widget.role,
      initialBookings: createSampleBookings(today, widget.role),
    );
  }

  Widget _buildHomeContent() {
    return HomeDashboard(
      onNotifications: _openNotifications,
      availableRooms: sampleRooms
          .where((room) => room.status == 'Trống')
          .length,
      onRooms: () => _selectTab(
        _ShellTab.schedule,
        bookingCategory: BookingCategory.rooms,
      ),
      onEquipment: () => _selectTab(
        _ShellTab.schedule,
        bookingCategory: BookingCategory.equipment,
      ),
      onSchedule: () =>
          _selectTab(_ShellTab.schedule, bookingCategory: BookingCategory.mine),
      onHistory: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => BookingHistoryPage(bookings: _bookings),
        ),
      ),
    );
  }
}
