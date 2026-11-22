import "package:flutter/material.dart";

import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/core/platform/app_permissions.dart';
import "package:uth_room_booking/features/room/data/sample_rooms.dart";
import "package:uth_room_booking/shared/layouts/bottom_navigation_bar.dart";
import "package:uth_room_booking/shared/layouts/header.dart";
import 'package:uth_room_booking/theme/app_colors.dart';

import '../../features/auth/models/user_role.dart';
import '../../features/booking/controllers/booking_controller.dart';
import '../../features/booking/data/asset_catalog.dart';
import '../../features/booking/data/booking_store.dart';
import '../../features/booking/data/sample_booking_data.dart';
import '../../features/booking/models/booking.dart';
import '../../features/booking/presentation/booking_history_page.dart';
import '../../features/booking/presentation/schedule_view.dart';
import '../../features/home/presentation/home_dashboard.dart';
import '../../features/incident_report/presentation/incident_report_view.dart';
import '../../features/incident_report/data/incident_report_store.dart';
import '../../features/notifications/data/notice_store.dart';
import '../../features/notifications/data/sample_notices.dart';
import '../../features/notifications/models/app_notice.dart';
import '../../features/profile/data/profile_avatar_storage.dart';
import '../../features/profile/data/profile_contact_store.dart';
import '../../features/profile/presentation/profile_view.dart';
import '../../features/technician/controllers/maintenance_proposal_controller.dart';
import '../../features/technician/controllers/technician_work_controller.dart';
import '../../features/technician/data/demo_incident_queue.dart';
import '../../features/technician/data/technician_incident_store.dart';
import '../../features/technician/models/task_filter.dart';
import '../../features/technician/presentation/technician_home_content.dart';
import '../../features/technician/presentation/technician_schedule_page.dart';
import '../../features/technician/presentation/technician_work_view.dart';

import 'shell_catalog_content.dart';

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
  final IncidentReportStore? incidentStore;
  final Future<void> Function()? onSignOut;
  final String? accountEmail;
  final String? faculty;
  final ProfileAvatarStorage? avatarStorage;
  final ProfileContactStore? contactStore;
  final Future<AssetCatalog> Function()? loadCatalog;
  final BookingStore? bookingStore;
  final NoticeStore? noticeStore;
  final TechnicianIncidentStore? technicianIncidentStore;

  const MainShell({
    super.key,
    required this.name,
    required this.id,
    this.role = UserRole.student,
    this.incidentQueue,
    this.incidentStore,
    this.onSignOut,
    this.accountEmail,
    this.faculty,
    this.avatarStorage,
    this.contactStore,
    this.loadCatalog,
    this.bookingStore,
    this.noticeStore,
    this.technicianIncidentStore,
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
  late final _assetCatalog = ShellCatalogController(
    load: () => widget.loadCatalog?.call(),
    onReload: () => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    final storage = widget.avatarStorage;
    if (storage != null) _loadAvatar(storage);
    if (!_isTechnician && widget.bookingStore != null) _refreshHomeBookings();
    if (_isTechnician) {
      _workController
        ..addListener(_workChanged)
        ..start(
          isWorkVisible: () =>
              (_selectedTab == _ShellTab.home &&
                  !_assetsVisible &&
                  !_maintenanceVisible) ||
              (_selectedTab == _ShellTab.work && !_showWorkSchedule),
        );
    }
    widget.noticeStore
      ?..addListener(_noticeChanged)
      ..start();
    if (widget.noticeStore != null && NoticeStore.supportsPush) {
      AppPermissions.onNoticeTap(_handleNoticeTap);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleNoticeTap();
      });
    }
  }

  Future<void> _handleNoticeTap() async {
    final noticeId = await AppPermissions.takeNoticeId();
    if (mounted && noticeId != null) {
      await _openNotifications(noticeId: noticeId);
    }
  }

  void _noticeChanged() => setState(() {});

  @override
  void dispose() {
    if (widget.noticeStore != null && NoticeStore.supportsPush) {
      AppPermissions.onNoticeTap(null);
    }
    if (_isTechnician) {
      _workController
        ..removeListener(_workChanged)
        ..dispose();
    } else {
      _bookings.dispose();
    }
    widget.noticeStore
      ?..removeListener(_noticeChanged)
      ..dispose();
    super.dispose();
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

  late final _incidentQueue = widget.incidentQueue ?? DemoIncidentQueue();
  late final _workController = TechnicianWorkController(
    store: widget.technicianIncidentStore,
    queue: _incidentQueue,
  );

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

  void _workChanged() => setState(() {
    if (_workFilter == TaskFilter.urgent &&
        !_workController.jobs.any(TaskFilter.urgent.matches)) {
      _workFilter = null;
    }
  });

  void _setWorkSchedule(bool value) =>
      setState(() => _showWorkSchedule = value);

  bool get _isTechnician => widget.role == UserRole.technician;
  List<AppNotice> get _notices =>
      widget.noticeStore?.notices ??
      (_isTechnician ? technicianNotices : demoNotices);

  void _openWork(TaskFilter? filter) {
    _workController.refresh();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _workFilter = filter;
      _showWorkSchedule = false;
      _selectedTab = _ShellTab.work;
    });
  }

  Future<void> _openNotifications({int? noticeId}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final store = widget.noticeStore;
    store?.refresh();
    await Navigator.of(context).pushNamed<void>(
      AppRoute.notifications,
      arguments: (
        read: store?.read ?? _readNotices,
        saved: store?.saved ?? _savedNotices,
        notices: _notices,
        store: store,
        bookingStore: widget.bookingStore,
        incidentStore: _isTechnician ? null : widget.incidentStore,
        technicianStore: widget.technicianIncidentStore,
        initialNoticeId: noticeId,
      ),
    );
    if (mounted && store == null) setState(() {});
  }

  void _selectTab(_ShellTab tab, {BookingCategory? bookingCategory}) {
    if (tab == _ShellTab.work) _workController.refresh();
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
    final shell = PopScope<void>(
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
            (notice) =>
                !(widget.noticeStore?.read ?? _readNotices).contains(notice.id),
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
                            store: widget.bookingStore,
                            active: _selectedTab == _ShellTab.work,
                          )
                        : TechnicianWorkView(
                            jobs: _workController.jobs,
                            filter: _workFilter,
                            onFilter: (filter) =>
                                setState(() => _workFilter = filter),
                            onChanged: _workController.taskChanged,
                            onSchedule: () => _setWorkSchedule(true),
                            loading: _workController.loading,
                            onRefresh: widget.technicianIncidentStore == null
                                ? null
                                : _workController.refresh,
                            onRetry: _workController.loadFailed
                                ? _workController.refresh
                                : null,
                          ),
                  _ShellTab.schedule => _assetCatalog.content(
                    (catalog) => ScheduleView(
                      bookings: _bookings,
                      noticeAccountId: widget.id,
                      categoryRequest: _bookingCategoryRequest,
                      catalog: catalog,
                      refreshCatalog: _assetCatalog.reload,
                      active: _selectedTab == _ShellTab.schedule,
                    ),
                  ),
                  _ShellTab.reports => _assetCatalog.content(
                    (catalog) => IncidentReportView(
                      avatar: _avatar,
                      name: widget.name,
                      id: widget.id,
                      role: widget.role,
                      queue: _incidentQueue,
                      store: widget.incidentStore,
                      loadCourses: widget.bookingStore?.courses,
                      active: _selectedTab == _ShellTab.reports,
                      assetDetails: {
                        for (final room in catalog?.rooms ?? [])
                          room.name: room.detail.split(' · ').first,
                        for (final device in catalog?.equipment ?? [])
                          device.name: device.detail,
                      },
                      roomNames: catalog?.rooms
                          .where(
                            (room) =>
                                room.slots.any(
                                  (slot) => slot != SlotStatus.maintenance,
                                ) &&
                                (widget.role != UserRole.teacher ||
                                    !catalog.roomsUnavailableToTeachers
                                        .contains(room.name)),
                          )
                          .map((room) => room.name),
                      equipmentNames: catalog?.equipment.map(
                        (device) => device.name,
                      ),
                    ),
                  ),
                  _ShellTab.profile => ProfileView(
                    id: widget.id,
                    role: widget.role,
                    onSignOut: widget.onSignOut == null
                        ? null
                        : () async {
                            try {
                              await widget.noticeStore?.unregisterPush();
                            } catch (_) {
                              // The server also checks that the session is active.
                            }
                            await widget.onSignOut!();
                          },
                    noticeStore: widget.noticeStore,
                    accountEmail: widget.accountEmail,
                    faculty: widget.faculty,
                    contactStore: widget.contactStore,
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
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: shell,
        ),
      ),
    );
  }

  Widget _buildTechnicianHome() => TechnicianHomeContent(
    jobs: _workController.jobs,
    notices: widget.noticeStore?.notices,
    catalog: _assetCatalog,
    refreshCatalog: widget.loadCatalog != null,
    showAssets: _showTechnicianAssets,
    showMaintenance: _showMaintenance,
    maintenance: _maintenance,
    maintenanceAsset: _maintenanceAsset,
    onWork: _openWork,
    onNotifications: _openNotifications,
    onAssets: () => _setTechnicianAssets(true),
    onMaintenance: _openMaintenance,
  );

  late final _bookings = _createBookingController();

  BookingController _createBookingController() {
    final today = DateUtils.dateOnly(
      widget.bookingStore == null ? DateTime.now() : BookingStore.campusNow,
    );
    return BookingController(
      today: today,
      role: widget.role,
      store: widget.bookingStore,
      initialBookings: widget.loadCatalog == null
          ? createSampleBookings(today, widget.role)
          : [],
    );
  }

  Future<void> _refreshHomeBookings() async {
    try {
      await _bookings.refreshHistory();
    } catch (_) {
      // Keep the last successful count available for the next refresh.
    }
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      _refreshHomeBookings(),
      if (widget.noticeStore case final store?) store.refresh(),
    ]);
  }

  Widget _buildHomeContent() => ListenableBuilder(
    listenable: _bookings,
    builder: (context, child) => HomeDashboard(
      onNotifications: _openNotifications,
      onRefresh: widget.bookingStore == null && widget.noticeStore == null
          ? null
          : _refreshHome,
      counts: _bookings.homeCounts(),
      notices: _notices,
      availableRooms: widget.loadCatalog == null
          ? sampleRooms.where((room) => room.status == 'Trống').length
          : null,
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
    ),
  );
}
