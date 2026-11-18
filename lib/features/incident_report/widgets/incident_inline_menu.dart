import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class IncidentInlineMenu<T extends Object> extends StatelessWidget {
  const IncidentInlineMenu({
    super.key,
    required this.triggerKey,
    required this.field,
    required this.options,
    required this.hint,
    required this.labelFor,
    required this.expanded,
    required this.onToggle,
    required this.onSelected,
    required this.decoration,
    this.iconFor,
    this.detailFor,
  });

  final Key triggerKey;
  final FormFieldState<T> field;
  final List<T> options;
  final String hint;
  final String Function(T) labelFor;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<T> onSelected;
  final InputDecoration decoration;
  final IconData Function(T?)? iconFor;
  final String? Function(T)? detailFor;

  @override
  Widget build(BuildContext context) {
    final iconFor = this.iconFor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: triggerKey,
            onTap: options.isEmpty ? null : onToggle,
            child: InputDecorator(
              decoration: decoration.copyWith(
                errorText: field.errorText,
                enabledBorder: expanded
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  if (iconFor != null) ...[
                    Icon(
                      iconFor(field.value),
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(switch (field.value) {
                      final value? => labelFor(value),
                      null => hint,
                    }),
                  ),
                  Icon(
                    expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded && options.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFD6E6E7)),
            ),
            child: Column(
              children: [
                for (final (index, option) in options.indexed) ...[
                  ListTile(
                    dense: true,
                    selected: field.value == option,
                    selectedTileColor: const Color(0xFFDCEFEF),
                    selectedColor: AppColors.primary,
                    leading: iconFor == null
                        ? null
                        : Icon(iconFor(option), size: 20),
                    title: Text(labelFor(option)),
                    subtitle: switch (detailFor?.call(option)) {
                      final detail? => Text(detail),
                      null => null,
                    },
                    trailing: iconFor != null && field.value == option
                        ? const Icon(Icons.check, size: 18)
                        : null,
                    onTap: () {
                      field.didChange(option);
                      onSelected(option);
                    },
                  ),
                  if (index < options.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0x22000000),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
