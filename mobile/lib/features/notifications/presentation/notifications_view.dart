import 'package:flutter/material.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

import '../../booking/data/booking_store.dart';
import '../../booking/widgets/booking_history_card.dart';
import '../../incident_report/data/incident_report_store.dart';
import '../../incident_report/widgets/incident_report_details_sheet.dart';
import '../data/notice_store.dart';
import '../data/sample_notices.dart';
import '../models/app_notice.dart';
import '../widgets/notice_card.dart';
import '../widgets/notice_search_filters.dart';

const _muted = Color(0xFF596577);

class NotificationsView extends StatefulWidget {
  const NotificationsView({
    super.key,
    required this.read,
    required this.saved,
    this.notices = demoNotices,
    this.store,
    this.bookingStore,
    this.incidentStore,
  });

  final List<AppNotice> notices;

  final Set<int> read;
  final Set<int> saved;
  final NoticeStore? store;
  final BookingStore? bookingStore;
  final IncidentReportStore? incidentStore;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  NoticeFilter _filter = NoticeFilter.all;
  String _query = '';
  final _pending = <int>{};
  final _selected = <int>{};
  bool _deleting = false;
  bool _deleteFailed = false;
  int? _openingIncidentId;

  void _toggleSelection(int id) {
    if (_deleting || _pending.contains(id)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _deleteFailed = false;
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _clearSelection() {
    _selected.clear();
    _deleteFailed = false;
  }

  Future<void> _deleteSelected(Set<int> ids) async {
    final store = widget.store;
    if (store == null || ids.isEmpty || _deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thông báo?'),
        content: Text('Xóa ${ids.length} thông báo đã chọn khỏi hộp thư?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _deleting) return;
    setState(() {
      _deleteFailed = false;
      _deleting = true;
    });
    try {
      await store.deleteNotices(ids);
      if (mounted) setState(_clearSelection);
    } catch (_) {
      if (mounted) setState(() => _deleteFailed = true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _runAction(int id, Future<void> Function() action) async {
    if (_pending.contains(id)) return;
    setState(() => _pending.add(id));
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Không thể xử lý thông báo. Vui lòng thử lại.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(id));
    }
  }

  void _openNotice(AppNotice notice) {
    if (_openingIncidentId != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final store = widget.store;
    if (store == null) {
      if (widget.read.add(notice.id)) setState(() {});
    } else {
      _runAction(notice.id, () => store.markRead(notice.id));
    }
    final incidentTitle = notice.incidentTitle;
    final createdAt = store?.createdAt(notice.id);
    final incidents = widget.incidentStore;
    if (incidents != null && incidentTitle != null && createdAt != null) {
      _openIncidentNotice(notice.id, incidents, incidentTitle, createdAt);
      return;
    }
    final bookingId = store?.bookingId(notice.id);
    final bookingDetails = bookingId == null
        ? null
        : widget.bookingStore?.bookingById(bookingId);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => NoticeDetailsSheet(
        notice: notice,
        relatedDetails: bookingDetails == null
            ? null
            : FutureBuilder(
                future: bookingDetails,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text('Chưa tải được chi tiết đăng ký.');
                  }
                  final booking = snapshot.data;
                  return booking == null
                      ? const Text('Đăng ký này hiện không còn khả dụng.')
                      : BookingHistoryCard(booking: booking);
                },
              ),
      ),
    );
  }

  Future<void> _openIncidentNotice(
    int noticeId,
    IncidentReportStore incidents,
    String title,
    String createdAt,
  ) async {
    setState(() => _openingIncidentId = noticeId);
    StoredIncidentReport? entry;
    try {
      entry = await incidents.reportForNotice(title, createdBefore: createdAt);
    } catch (_) {
      // The inbox can still be used when the report cannot be loaded.
    } finally {
      if (mounted) setState(() => _openingIncidentId = null);
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final report = entry;
    if (report == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa mở được báo cáo. Bạn có thể xem trong Báo cáo của tôi.',
            ),
          ),
        );
      return;
    }
    final evidence = report.hasPhoto
        ? incidents.loadPhoto(report.id).catchError((Object _) => null)
        : null;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (context) => IncidentReportDetailsSheet(
        report: report.report,
        status: report.status,
        canCancel: false,
        updatedAt: report.updatedAt,
        evidence: evidence,
      ),
    );
  }

  void _toggleSaved(int id, bool saved) {
    final store = widget.store;
    if (store != null) {
      _runAction(id, () => store.setSaved(id, !saved));
    } else {
      setState(() {
        if (saved) {
          widget.saved.remove(id);
        } else {
          widget.saved.add(id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return store == null
        ? _buildInbox()
        : ListenableBuilder(
            listenable: store,
            builder: (_, _) => _buildInbox(),
          );
  }

  Widget _buildInbox() {
    final store = widget.store;
    final visibleNotices = (store?.notices ?? widget.notices).where((notice) {
      final matchesFilter = switch (_filter) {
        NoticeFilter.all => true,
        NoticeFilter.unread => !widget.read.contains(notice.id),
        NoticeFilter.saved => widget.saved.contains(notice.id),
      };
      return matchesFilter &&
          '${notice.title} ${notice.message} ${notice.metadata}'
              .toLowerCase()
              .contains(_query);
    }).toList();
    final selecting = _selected.isNotEmpty;
    final selectableIds = visibleNotices
        .map((notice) => notice.id)
        .where((id) => !_pending.contains(id))
        .toSet();
    final selectedIds = _selected.intersection(selectableIds);

    final content = SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoticeSearchFilters(
            selected: _filter,
            disabled: _deleting,
            onQueryChanged: (value) => setState(() {
              _query = value.trim().toLowerCase();
              _clearSelection();
            }),
            onFilterChanged: (filter) => setState(() {
              if (_filter != filter) _clearSelection();
              _filter = filter;
            }),
          ),
          if (_deleting) const LinearProgressIndicator(),
          if (_deleteFailed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Không thể xóa thông báo. Vui lòng thử lại.'),
            ),
          Expanded(
            child: _refreshable(
              store?.loading == true
                  ? const Center(child: CircularProgressIndicator())
                  : store?.loadFailed == true && store!.notices.isEmpty
                  ? _InboxMessage(
                      child: TextButton(
                        onPressed: store.refresh,
                        child: const Text('Không tải được thông báo. Thử lại'),
                      ),
                    )
                  : visibleNotices.isEmpty
                  ? const _InboxMessage(
                      child: Text(
                        'Không có thông báo',
                        style: TextStyle(color: _muted),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      itemCount: visibleNotices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final notice = visibleNotices[index];
                        final saved = widget.saved.contains(notice.id);
                        final isRead = widget.read.contains(notice.id);
                        final selected = selectedIds.contains(notice.id);
                        final disabled =
                            _deleting || _pending.contains(notice.id);
                        return NoticeCard(
                          opening: _openingIncidentId == notice.id,
                          notice: notice,
                          isRead: isRead,
                          saved: saved,
                          selecting: selecting,
                          selected: selected,
                          onTap: disabled
                              ? null
                              : selecting
                              ? () => _toggleSelection(notice.id)
                              : () => _openNotice(notice),
                          onLongPress: store == null || disabled
                              ? null
                              : () => _toggleSelection(notice.id),
                          onSave: disabled
                              ? null
                              : () => _toggleSaved(notice.id, saved),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: !selecting && !_deleting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selecting && !_deleting) setState(_clearSelection);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          leading: selecting
              ? IconButton(
                  tooltip: 'Thoát chế độ chọn',
                  onPressed: _deleting ? null : () => setState(_clearSelection),
                  icon: const Icon(Icons.close),
                )
              : null,
          title: Text(
            selecting ? 'Đã chọn ${selectedIds.length}' : 'Thông báo',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: selecting ? 16 : 21,
            ),
          ),
          actions: selecting
              ? [
                  TextButton(
                    onPressed: _deleting || selectableIds.isEmpty
                        ? null
                        : () => setState(() {
                            _selected
                              ..clear()
                              ..addAll(selectableIds);
                            _deleteFailed = false;
                          }),
                    child: const Text('Chọn tất cả'),
                  ),
                  IconButton(
                    tooltip: 'Xóa thông báo đã chọn',
                    onPressed: _deleting || selectedIds.isEmpty
                        ? null
                        : () => _deleteSelected(selectedIds),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ]
              : null,
        ),
        body: content,
      ),
    );
  }

  Widget _refreshable(Widget child) {
    final store = widget.store;
    return store == null
        ? child
        : RefreshIndicator(onRefresh: store.refresh, child: child);
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
    ],
  );
}
