import 'package:flutter/material.dart';

import '../data/sample_notices.dart';
import '../models/app_notice.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _muted = Color(0xFF596577);
const _border = Color(0xFFDFE5EA);

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
  });

  final List<AppNotice> notices;

  final Set<int> read;
  final Set<int> saved;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  _NoticeFilter _filter = _NoticeFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visibleNotices = widget.notices.where((notice) {
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

    final content = SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 4),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
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
                        onPressed: () => setState(() => _filter = filter),
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
          Expanded(
            child: visibleNotices.isEmpty
                ? const Center(
                    child: Text(
                      'Không có thông báo',
                      style: TextStyle(color: _muted),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    itemCount: visibleNotices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final notice = visibleNotices[index];
                      final saved = widget.saved.contains(notice.id);
                      final isRead = widget.read.contains(notice.id);
                      return Material(
                        color: isRead ? Colors.white : const Color(0xFFF0F8F8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                          side: const BorderSide(color: _border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            if (widget.read.add(notice.id)) {
                              setState(() {});
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFE3F2F3),
                                  foregroundColor: AppColors.primary,
                                  child: Icon(notice.icon, size: 21),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notice.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF172033),
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notice.message,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notice.metadata,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: saved
                                      ? 'Bỏ lưu thông báo'
                                      : 'Lưu thông báo',
                                  onPressed: () => setState(() {
                                    if (saved) {
                                      widget.saved.remove(notice.id);
                                    } else {
                                      widget.saved.add(notice.id);
                                    }
                                  }),
                                  icon: Icon(
                                    saved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
        ),
      ),
      body: content,
    );
  }
}
