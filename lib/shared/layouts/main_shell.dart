import 'dart:async';

import "package:flutter/material.dart";

import 'package:uth_room_booking/core/router/app_route.dart';
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
import '../../features/profile/presentation/profile_view.dart';
import '../../features/technician/controllers/maintenance_proposal_controller.dart';
import '../../features/technician/data/demo_incident_queue.dart';
import '../../features/technician/data/technician_work_store.dart';
import '../../features/technician/models/task_filter.dart';
import '../../features/technician/models/technician_task.dart';
import '../../features/technician/presentation/maintenance_proposals_page.dart';
import '../../features/technician/presentation/technician_assets_page.dart';
import '../../features/technician/presentation/technician_dashboard.dart';
import '../../features/technician/presentation/technician_schedule_page.dart';
import '../../features/technician/presentation/technician_work_view.dart';

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
  final TechnicianWorkStore? workStore;
  final Future<void> Function()? onSignOut;
  final String? accountEmail;
  final String? faculty;
  final ProfileAvatarStorage? avatarStorage;
  final Future<AssetCatalog> Function()? loadCatalog;
  final BookingStore? bookingStore;
  final NoticeStore? noticeStore;

  const MainShell({
    super.key,
    required this.name,
    required this.id,
    this.role = UserRole.student,
    this.incidentQueue,
    this.incidentStore,
    this.workStore,
    this.onSignOut,
    this.accountEmail,
    this.faculty,
    this.avatarStorage,
    this.loadCatalog,
    this.bookingStore,
    this.noticeStore,
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
  AssetCatalog? _lastCatalog;
  Future<AssetCatalog?>? _catalogReload;
  late Future<AssetCatalog>? _catalog = _loadCatalog();

  Future<AssetCatalog>? _loadCatalog() =>
      widget.loadCatalog?.call().then((catalog) => _lastCatalog = catalog);

  Future<AssetCatalog?> _reloadCatalog() => _catalogReload ??=
      _reloadCatalogOnce().whenComplete(() => _catalogReload = null);

  Future<AssetCatalog?> _reloadCatalogOnce() async {
    final request = _loadCatalog();
    if (request == null) return null;
    setState(() {
      _catalog = request;
    });
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Widget _withCatalog(Widget Function(AssetCatalog?) builder) {
    final catalog = _catalog;
    if (catalog == null) return builder(null);
    return FutureBuilder<AssetCatalog>(
      future: catalog,
      builder: (context, snapshot) {
        final available = snapshot.data ?? _lastCatalog;
        if (available != null) return builder(available);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: _reloadCatalog,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: TextButton(
                      onPressed: _reloadCatalog,
                      child: const Text('Không tải được danh mục. Thử lại'),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return builder(snapshot.requireData);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final storage = widget.avatarStorage;
    if (storage != null) _loadAvatar(storage);
    if (!_isTechnician && widget.bookingStore != null) _refreshHomeBookings();
    if (_isTechnician && widget.workStore != null) {
      unawaited(_loadWork());
      _workTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(_loadWork()),
      );
    }
    widget.noticeStore
      ?..addListener(_noticeChanged)
      ..start();
  }

  void _noticeChanged() => setState(() {});

  @override
  void dispose() {
    _workTimer?.cancel();
    if (!_isTechnician) _bookings.dispose();
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

  late final _sampleJobs = createSampleTechnicianTasks();
  late final _incidentQueue = widget.incidentQueue ?? DemoIncidentQueue();
  List<TechnicianTask> get _jobs => widget.workStore == null
      ? [..._incidentQueue.tasks, ..._sampleJobs]
      : _remoteJobs;
  List<TechnicianTask> _remoteJobs = [];
  Timer? _workTimer;
  Future<void>? _loadingWork;
  bool _workBusy = false;
  String? _workError;

  Future<void> _loadWork() =>
      _loadingWork ??= _loadWorkOnce().whenComplete(() => _loadingWork = null);

  Future<void> _loadWorkOnce() async {
    final store = widget.workStore;
    if (!mounted || store == null || _remoteJobs.any((task) => task.saving)) {
      return;
    }
    setState(() {
      _workBusy = true;
      _workError = null;
    });
    try {
      final jobs = await store.load();
      if (mounted && !_remoteJobs.any((task) => task.saving)) {
        setState(() => _remoteJobs = jobs);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _workError = 'Không tải được công việc đã duyệt. Thử lại',
        );
      }
    } finally {
      if (mounted) setState(() => _workBusy = false);
    }
  }

  Widget _withWorkStatus(Widget child) => Column(
    children: [
      if (_workBusy) const LinearProgressIndicator(),
      if (_workError case final error?)
        TextButton(onPressed: _loadWork, child: Text(error)),
      Expanded(child: child),
    ],
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

  void _refreshWork() {
    if (!mounted) return;
    setState(() {
      if (_workFilter == TaskFilter.urgent &&
          !_jobs.any(TaskFilter.urgent.matches)) {
        _workFilter = null;
      }
    });
    unawaited(_loadWork());
  }

  void _setWorkSchedule(bool value) =>
      setState(() => _showWorkSchedule = value);

  bool get _isTechnician => widget.role == UserRole.technician;
  List<AppNotice> get _notices =>
      widget.noticeStore?.notices ??
      (_isTechnician ? technicianNotices : demoNotices);

  void _openWork(TaskFilter? filter) {
    unawaited(_loadWork());
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _workFilter = filter;
      _showWorkSchedule = false;
      _selectedTab = _ShellTab.work;
    });
  }

  Future<void> _openNotifications() async {
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
      ),
    );
    if (mounted && store == null) setState(() {});
  }

  void _selectTab(_ShellTab tab, {BookingCategory? bookingCategory}) {
    if (_isTechnician && (tab == _ShellTab.work || tab == _ShellTab.home)) {
      unawaited(_loadWork());
    }
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
                        : _withWorkStatus(
                            TechnicianWorkView(
                              jobs: _jobs,
                              filter: _workFilter,
                              onFilter: (filter) =>
                                  setState(() => _workFilter = filter),
                              onChanged: _refreshWork,
                              onSchedule: () => _setWorkSchedule(true),
                              onRefresh: widget.workStore == null
                                  ? null
                                  : _loadWork,
                            ),
                          ),
                  _ShellTab.schedule => _withCatalog(
                    (catalog) => ScheduleView(
                      bookings: _bookings,
                      categoryRequest: _bookingCategoryRequest,
                      catalog: catalog,
                      refreshCatalog: _reloadCatalog,
                      active: _selectedTab == _ShellTab.schedule,
                    ),
                  ),
                  _ShellTab.reports => IncidentReportView(
                    avatar: _avatar,
                    name: widget.name,
                    id: widget.id,
                    role: widget.role,
                    queue: _incidentQueue,
                    store: widget.incidentStore,
                    active: _selectedTab == _ShellTab.reports,
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

  Widget _buildTechnicianHome() => _withWorkStatus(
    IndexedStack(
      index: _showMaintenance
          ? (_showTechnicianAssets ? 2 : 1)
          : (_showTechnicianAssets ? 1 : 0),
      children: [
        TechnicianDashboard(
          jobs: _jobs,
          notices: widget.noticeStore?.notices,
          onWork: _openWork,
          onNotifications: _openNotifications,
          onAssets: () => _setTechnicianAssets(true),
          onMaintenance: _openMaintenance,
        ),
        if (_showTechnicianAssets)
          _withCatalog(
            (catalog) => TechnicianAssetsPage(
              onAsset: (asset) => _openMaintenance(asset: asset),
              catalog: catalog,
              onRefresh: widget.loadCatalog == null ? null : _reloadCatalog,
            ),
          ),
        if (_showMaintenance)
          _withCatalog(
            (catalog) => MaintenanceProposalsPage(
              controller: _maintenance,
              initialAsset: _maintenanceAsset,
              catalog: catalog,
            ),
          ),
      ],
    ),
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
