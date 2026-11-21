import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.keys.toList().indexOf(selected);
    final position = options.length > 1
        ? -1.0 + 2.0 * selectedIndex / (options.length - 1)
        : 0.0;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          if (selectedIndex >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                alignment: AlignmentDirectional(position, 0),
                duration: duration,
                curve: Curves.easeInOut,
                child: FractionallySizedBox(
                  widthFactor: 1 / options.length,
                  heightFactor: 1,
                  child: const DecoratedBox(
                    decoration: ShapeDecoration(
                      color: AppColors.primary,
                      shape: StadiumBorder(),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final option in options.entries)
                Expanded(
                  child: Semantics(
                    selected: option.key == selected,
                    child: Material(
                      color: Colors.transparent,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelected(option.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                          child: Text(
                            option.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: option.key == selected
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
