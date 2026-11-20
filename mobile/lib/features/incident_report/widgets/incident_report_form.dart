import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/app_permissions.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_role.dart';
import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';
import '../../equipment/data/sample_devices.dart';
import '../../room/data/sample_rooms.dart';
import '../models/incident_report.dart';
import 'incident_inline_menu.dart';
import 'incident_report_controls.dart';
import 'incident_photo_picker.dart';
import 'incident_photo_field.dart';
import 'incident_report_labels.dart';
import 'incident_reporter_card.dart';

const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

enum _IncidentType {
  room('Phòng máy', Icons.desktop_windows_outlined),
  equipment('Thiết bị', Icons.devices_other_outlined);

  const _IncidentType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class IncidentReportForm extends StatefulWidget {
  const IncidentReportForm({
    super.key,
    required this.name,
    required this.id,
    required this.role,
    required this.nextReportId,
    required this.onSubmitted,
    this.avatar,
    this.roomNames,
    this.equipmentNames,
    this.assetDetails = const {},
    this.loadCourses,
  });

  final String name;
  final String id;
  final UserRole role;
  final int Function() nextReportId;
  final Future<bool> Function(IncidentReport, ValueChanged<bool>) onSubmitted;
  final ImageProvider? avatar;
  final Iterable<String>? roomNames;
  final Iterable<String>? equipmentNames;
  final Map<String, String> assetDetails;
  final Future<List<CourseSection>> Function()? loadCourses;

  @override
  State<IncidentReportForm> createState() => _IncidentReportFormState();
}

class _IncidentReportFormState extends State<IncidentReportForm> {
  Uint8List? _photo;
  bool _pickingPhotos = false;
  bool _submitting = false;
  bool _uploadingPhoto = false;
  String? _submitError;
  var _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _course = '';
  late Future<List<CourseSection>> _courses =
      widget.loadCourses?.call() ?? Future.value(sampleTeachingCourses);
  _IncidentType _type = _IncidentType.room;
  bool _needsTeachingSupport = false;
  String? _asset;
  bool _assetMenuOpen = false;
  bool _courseMenuOpen = false;

  bool get _isTeachingRoom =>
      widget.role == UserRole.teacher && _type == _IncidentType.room;

  Iterable<String> get _assets => switch (_type) {
    _IncidentType.room =>
      widget.roomNames ??
          sampleRooms
              .where((room) => room.status != 'Bảo trì')
              .map((room) => room.name),
    _IncidentType.equipment =>
      widget.equipmentNames ?? sampleDevices.map((device) => device.name),
  };

  InputDecoration _input({String? hint}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _line),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPhoto() async {
    if (_pickingPhotos) return;
    setState(() => _pickingPhotos = true);
    try {
      final photo = await pickIncidentPhoto(context);
      if (mounted && photo != null) setState(() => _photo = photo);
    } on PlatformException catch (error) {
      if (!mounted) return;
      if (error.code == 'camera_access_denied' ||
          error.code == 'camera_access_restricted') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera chưa được cấp quyền.'),
            action: SnackBarAction(
              label: 'Cài đặt',
              onPressed: () => AppPermissions.openSettings(),
            ),
          ),
        );
      } else {
        _showMessage('Không thể mở camera hoặc thư viện ảnh.');
      }
    } on Exception {
      if (mounted) _showMessage('Không thể thêm ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState!;
    final asset = _asset;
    if (!form.validate() || asset == null) return;
    form.save();
    FocusScope.of(context).unfocus();
    final report = (
      id: widget.nextReportId(),
      title: _title,
      description: _description,
      type: _type.label,
      asset: asset,
      course: _isTeachingRoom ? _course : '',
      needsSupport: _isTeachingRoom && _needsTeachingSupport,
      submittedAt: DateTime.now(),
      photos: List<Uint8List>.unmodifiable([?_photo]),
    );
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final sent = await widget.onSubmitted(report, (uploading) {
        if (mounted) setState(() => _uploadingPhoto = uploading);
      });
      if (!sent) {
        if (mounted) {
          setState(
            () => _submitError = 'Không gửi được báo cáo. Vui lòng thử lại.',
          );
        }
        return;
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
      return;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    setState(() {
      _formKey = GlobalKey<FormState>();
      _type = _IncidentType.room;
      _asset = null;
      _assetMenuOpen = false;
      _courseMenuOpen = false;
      _course = '';
      _needsTeachingSupport = false;
      _photo = null;
    });
  }

  String? _requiredText(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  String _courseLabel(CourseSection course) =>
      '${course.code} · ${course.name}';

  Widget _buildCourseField() => FutureBuilder<List<CourseSection>>(
    future: _courses,
    builder: (context, snapshot) {
      final courses = snapshot.data ?? const <CourseSection>[];
      final hint = snapshot.connectionState == ConnectionState.waiting
          ? 'Đang tải lớp học phần...'
          : snapshot.hasError
          ? 'Không tải được lớp học phần'
          : courses.isEmpty
          ? 'Chưa được phân công lớp học phần'
          : 'Chọn lớp học phần';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormField<CourseSection>(
            onSaved: (course) =>
                _course = course == null ? '' : _courseLabel(course),
            builder: (field) => IncidentInlineMenu(
              decoration: _input(),
              triggerKey: const ValueKey('incident-course-menu'),
              field: field,
              options: courses,
              hint: hint,
              labelFor: _courseLabel,
              expanded: _courseMenuOpen,
              onToggle: () => setState(() {
                _courseMenuOpen = !_courseMenuOpen;
                _assetMenuOpen = false;
              }),
              onSelected: (_) => setState(() => _courseMenuOpen = false),
            ),
          ),
          if (snapshot.hasError)
            TextButton(
              onPressed: () {
                final request = widget.loadCourses?.call();
                if (request == null) return;
                setState(() {
                  _courses = request;
                });
              },
              child: const Text('Tải lại lớp học phần'),
            ),
        ],
      );
    },
  );

  IconData _assetIcon(String? name) => switch (_type) {
    _IncidentType.room when name?.toLowerCase().contains('thư viện') == true =>
      Icons.local_library_outlined,
    _ => _type.icon,
  };

  Widget _buildAssetField(List<String> assets) => FormField<String>(
    key: ValueKey(_type),
    initialValue: _asset,
    autovalidateMode: AutovalidateMode.onUserInteractionIfError,
    validator: (asset) =>
        assets.contains(asset) ? null : 'Vui lòng chọn vị trí hoặc đối tượng',
    builder: (field) => IncidentInlineMenu(
      decoration: _input(),
      triggerKey: const ValueKey('incident-asset-menu'),
      field: field,
      options: assets,
      hint: _type == _IncidentType.room ? 'Chọn phòng máy' : 'Chọn thiết bị',
      labelFor: (asset) => asset,
      expanded: _assetMenuOpen,
      iconFor: _assetIcon,
      detailFor: (asset) => widget.assetDetails[asset],
      onToggle: () => setState(() {
        _assetMenuOpen = !_assetMenuOpen;
        _courseMenuOpen = false;
      }),
      onSelected: (asset) => setState(() {
        _asset = asset;
        _assetMenuOpen = false;
      }),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final assets = _assets.toList();
    return AbsorbPointer(
      absorbing: _submitting,
      child: Form(
        key: _formKey,
        onChanged: () {
          if (_submitError != null) setState(() => _submitError = null);
        },
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IncidentReporterCard(
                avatar: widget.avatar,
                name: widget.name,
                id: widget.id,
                role: widget.role,
              ),
              const IncidentFieldTitle('Loại sự cố'),
              Row(
                children: [
                  for (final type in _IncidentType.values) ...[
                    if (type != _IncidentType.values.first)
                      const SizedBox(width: 8),
                    Expanded(
                      child: IncidentTypeOption(
                        selected: _type == type,
                        icon: type.icon,
                        label: type.label,
                        onPressed: () => _selectType(type),
                      ),
                    ),
                  ],
                ],
              ),
              const IncidentFieldTitle('Vị trí / đối tượng'),
              _buildAssetField(assets),
              if (_isTeachingRoom) ...[
                const IncidentFieldTitle('Lớp học phần đang dạy'),
                _buildCourseField(),
              ],
              const IncidentFieldTitle('Tiêu đề'),
              TextFormField(
                decoration: _input(hint: 'Tóm tắt sự cố'),
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                textInputAction: TextInputAction.next,
                onSaved: (value) => _title = value!.trim(),
                validator: (value) =>
                    _requiredText(value, 'Vui lòng nhập tiêu đề'),
              ),
              const IncidentFieldTitle('Mô tả chi tiết'),
              TextFormField(
                minLines: 3,
                maxLines: 5,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                onSaved: (value) => _description = value!.trim(),
                decoration: _input(
                  hint: 'Mô tả hiện tượng, các bước dẫn đến lỗi…',
                ),
                validator: (value) =>
                    _requiredText(value, 'Vui lòng mô tả sự cố'),
              ),
              IncidentPhotoField(
                photo: _photo,
                uploading: _uploadingPhoto,
                onPick: _pickingPhotos ? null : _addPhoto,
                onRemove: _pickingPhotos
                    ? null
                    : () => setState(() => _photo = null),
              ),
              if (_isTeachingRoom) ...[
                const SizedBox(height: 16),
                IncidentTeachingSupportSwitch(
                  enabled: _needsTeachingSupport,
                  onChanged: (value) =>
                      setState(() => _needsTeachingSupport = value),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickingPhotos || _submitting ? null : _submit,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text(_submitting ? 'Đang gửi…' : 'Gửi báo cáo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _submitting
                      ? AppColors.primary
                      : null,
                  disabledForegroundColor: _submitting ? Colors.white : null,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (_submitError case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectType(_IncidentType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _asset = null;
      _assetMenuOpen = false;
      _courseMenuOpen = false;
      _course = '';
      _needsTeachingSupport = false;
    });
  }
}
