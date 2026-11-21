import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class BookingCategoryTabs<T> extends StatelessWidget {
  const BookingCategoryTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexWhere((option) => option.$1 == selected);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                alignment: AlignmentDirectional(
                  options.length > 1
                      ? 2 * selectedIndex / (options.length - 1) - 1
                      : 0,
                  0,
                ),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: FractionallySizedBox(
                  widthFactor: 1 / options.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final (value, label) in options)
                  Expanded(
                    child: Semantics(
                      selected: selected == value,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 7,
                          ),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: selected == value
                              ? AppColors.primary
                              : const Color(0xFF526E74),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (selected != value) onChanged(value);
                        },
                        child: Text(label, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
