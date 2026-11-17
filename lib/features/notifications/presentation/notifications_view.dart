import 'package:flutter/material.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

import '../../booking/data/booking_store.dart';
import '../../booking/widgets/booking_history_card.dart';
import '../data/notice_store.dart';
import '../data/sample_notices.dart';
import '../models/app_notice.dart';
import '../widgets/notice_card.dart';

const _muted = Color(0xFF596577);

enum _NoticeFilter {
  all('Tất cả'),
  unread('Chưa đọc'),
  saved('Đã lưu');

  const _NoticeFilter(this.label);
  final String label;
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({
    super.key,
    required this.read,
    required this.saved,
    this.notices = demoNotices,
    this.store,
    this.bookingStore,
  });

  final List<AppNotice> notices;

  final Set<int> read;
  final Set<int> saved;
  final NoticeStore? store;
  final BookingStore? bookingStore;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  _NoticeFilter _filter = _NoticeFilter.all;
  String _query = '';
  final _pending = <int>{};
  final _selected = <int>{};
  bool _deleting = false;
  bool _deleteFailed = false;

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
    final store = widget.store;
    if (store == null) {
      if (widget.read.add(notice.id)) setState(() {});
      return;
    }
    _runAction(notice.id, () async {
      await store.markRead(notice.id);
      final id = store.bookingId(notice.id);
      final bookings = widget.bookingStore;
      if (!mounted || id == null || bookings == null) return;
      final booking = await bookings.bookingById(id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: booking == null
                ? const Text('Đăng ký này hiện không còn khả dụng.')
                : BookingHistoryCard(booking: booking),
          ),
        ),
      );
    });
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
        _NoticeFilter.all => true,
        _NoticeFilter.unread => !widget.read.contains(notice.id),
        _NoticeFilter.saved => widget.saved.contains(notice.id),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 4),
            child: TextField(
              enabled: !_deleting,
              onChanged: (value) => setState(() {
                _query = value.trim().toLowerCase();
                _clearSelection();
              }),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thông báo...',
                prefixIcon: const Icon(Icons.search, color: _muted),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F2F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (final filter in _NoticeFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Semantics(
                      selected: _filter == filter,
                      child: TextButton(
                        onPressed: _deleting
                            ? null
                            : () => setState(() {
                                if (_filter != filter) _clearSelection();
                                _filter = filter;
                              }),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          foregroundColor: _filter == filter
                              ? AppColors.primary
                              : _muted,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(filter.label),
                            const SizedBox(height: 5),
                            Container(
                              width: 23,
                              height: 2,
                              color: _filter == filter
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
