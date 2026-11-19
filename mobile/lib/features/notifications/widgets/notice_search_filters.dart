import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

const _muted = Color(0xFF596577);

enum NoticeFilter {
  all('Tất cả'),
  unread('Chưa đọc'),
  saved('Đã lưu');

  const NoticeFilter(this.label);
  final String label;
}

class NoticeSearchFilters extends StatelessWidget {
  const NoticeSearchFilters({
    super.key,
    required this.selected,
    required this.disabled,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final NoticeFilter selected;
  final bool disabled;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<NoticeFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 4),
        child: TextField(
          enabled: !disabled,
          onChanged: onQueryChanged,
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
            for (final filter in NoticeFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Semantics(
                  selected: selected == filter,
                  child: TextButton(
                    onPressed: disabled ? null : () => onFilterChanged(filter),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      foregroundColor: selected == filter
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
                          color: selected == filter
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
    ],
  );
}
