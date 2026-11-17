import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../controllers/booking_controller.dart';
import '../data/sample_booking_data.dart';
import '../models/booking.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFACD6D6);
const _muted = Color(0xFF526E74);

typedef BookingSelection = ({CourseSection? section, int? studentCount});

class BookingConfirmationSheet extends StatefulWidget {
  const BookingConfirmationSheet({
    super.key,
    required this.slot,
    required this.asset,
    required this.role,
  });

  final BookingSlot slot;
  final BookingAsset asset;
  final UserRole role;

  @override
  State<BookingConfirmationSheet> createState() =>
      _BookingConfirmationSheetState();
}

class _BookingConfirmationSheetState extends State<BookingConfirmationSheet> {
  static const _minimum = BookingController.minimumStudentCount;
  final _form = GlobalKey<FormState>();
  int _studentCount = _minimum;
  bool _customCount = false;
  CourseSection? _section;

  bool get _isRoom => widget.asset.capacity > 0;
  bool get _needsCount => _isRoom && widget.role == UserRole.student;

  void _confirm() {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    Navigator.of(context).pop<BookingSelection>((
      section: _section,
      studentCount: _needsCount ? _studentCount : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final inset = MediaQuery.sizeOf(context).width < 360 ? 16.0 : 24.0;
    return Padding(
      padding: EdgeInsets.only(
        bottom: keyboard > 0
            ? keyboard
            : kBottomNavigationBarHeight +
                  MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Material(
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          side: BorderSide(color: _line),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(inset, 14, inset, 24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _pale,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          _isRoom
                              ? Icons.desktop_windows_outlined
                              : Icons.devices_other_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.asset.name} · Ca ${slot.index + 1}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${slot.date.day}/${slot.date.month} · '
                            '${bookingStartTimes[slot.index]} – ${bookingEndTimes[slot.index]}',
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_needsCount) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Số người',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      for (final count in [_minimum, 15, 20])
                        if (count <= widget.asset.capacity)
                          _countChip(
                            '$count',
                            !_customCount && _studentCount == count,
                            () => setState(() {
                              _customCount = false;
                              _studentCount = count;
                            }),
                          ),
                      if (widget.asset.capacity > _minimum)
                        _countChip(
                          'Khác',
                          _customCount,
                          () => setState(() => _customCount = true),
                        ),
                    ],
                  ),
                  if (_customCount) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: '$_studentCount',
                      decoration: const InputDecoration(
                        labelText: 'Số sinh viên',
                      ),
                      validator: (value) {
                        final count = int.tryParse(value?.trim() ?? '');
                        if (count == null || count < _minimum) {
                          return 'Cần ít nhất $_minimum sinh viên';
                        }
                        if (count > widget.asset.capacity) {
                          return 'Vượt sức chứa của phòng';
                        }
                        return null;
                      },
                      onSaved: (value) =>
                          _studentCount = int.parse(value!.trim()),
                    ),
                  ],
                ],
                if (widget.role == UserRole.teacher) ...[
                  const SizedBox(height: 20),
                  DropdownButtonFormField<CourseSection>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Lớp học phần',
                    ),
                    items: [
                      for (final course in sampleTeachingCourses)
                        DropdownMenuItem(
                          value: course,
                          child: Text(
                            '${course.code} · ${course.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (course) => _section = course,
                    validator: (course) =>
                        course == null ? 'Vui lòng chọn lớp học phần' : null,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(_isRoom ? 'Đặt phòng' : 'Đặt thiết bị'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countChip(String label, bool selected, VoidCallback onTap) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        backgroundColor: _pale,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: _line),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.primary,
        ),
        onSelected: (_) => onTap(),
      );
}
