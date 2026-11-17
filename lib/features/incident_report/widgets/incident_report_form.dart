import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/app_permissions.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_role.dart';
import '../../equipment/data/sample_devices.dart';
import '../../room/data/sample_rooms.dart';
import '../models/incident_report.dart';
import 'incident_photo_picker.dart';
import 'incident_photo_field.dart';
import 'incident_report_labels.dart';
import 'incident_reporter_card.dart';
import 'incident_time_field.dart';

const _pale = Color(0xFFDCEFEF);
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
  });

  final String name;
  final String id;
  final UserRole role;
  final int Function() nextReportId;
  final Future<bool> Function(IncidentReport) onSubmitted;
  final ImageProvider? avatar;
  final Iterable<String>? roomNames;
  final Iterable<String>? equipmentNames;

  @override
  State<IncidentReportForm> createState() => _IncidentReportFormState();
}

class _IncidentReportFormState extends State<IncidentReportForm> {
  Uint8List? _photo;
  bool _pickingPhotos = false;
  bool _submitting = false;
  String? _submitError;
  var _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _course = '';
  _IncidentType _type = _IncidentType.room;
  bool _needsTeachingSupport = false;
  String? _asset;
  DateTime _occurredAt = DateTime.now();

  bool get _isTeacher => widget.role == UserRole.teacher;

  Iterable<String> get _assets => switch (_type) {
    _IncidentType.room =>
      widget.roomNames ?? sampleRooms.map((room) => room.name),
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

  Future<void> _chooseTime() async {
    final selected = await pickIncidentTime(context, _occurredAt);
    if (mounted && selected != null) setState(() => _occurredAt = selected);
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
      course: _isTeacher ? _course : '',
      needsSupport: _isTeacher && _needsTeachingSupport,
      occurredAt: _occurredAt,
      submittedAt: DateTime.now(),
      photos: List<Uint8List>.unmodifiable([?_photo]),
    );
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      if (!await widget.onSubmitted(report)) {
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
      _course = '';
      _needsTeachingSupport = false;
      _occurredAt = DateTime.now();
      _photo = null;
    });
  }

  String? _requiredText(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _submitting,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    Expanded(child: _buildType(type)),
                  ],
                ],
              ),
              const IncidentFieldTitle('Vị trí / đối tượng'),
              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _asset,
                decoration: _input(),
                hint: Text(
                  _type == _IncidentType.room
                      ? 'Chọn phòng máy'
                      : 'Chọn thiết bị',
                ),
                isExpanded: true,
                items: [
                  for (final asset in _assets)
                    DropdownMenuItem(value: asset, child: Text(asset)),
                ],
                onChanged: (asset) => setState(() => _asset = asset),
                validator: (asset) => asset == null
                    ? 'Vui lòng chọn vị trí hoặc đối tượng'
                    : null,
              ),
              if (_isTeacher) ...[
                const IncidentFieldTitle('Lớp học phần đang dạy'),
                TextFormField(
                  decoration: _input(hint: 'Lập trình di động - Nhóm 02')
                      .copyWith(
                        helperText: _needsTeachingSupport
                            ? 'Bắt buộc khi cần hỗ trợ ngay'
                            : null,
                      ),
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _course = value?.trim() ?? '',
                  validator: (value) => _needsTeachingSupport
                      ? _requiredText(
                          value,
                          'Vui lòng nhập lớp học phần đang dạy',
                        )
                      : null,
                ),
              ],
              const IncidentFieldTitle('Tiêu đề'),
              TextFormField(
                decoration: _input(hint: 'Máy số 12 không lên nguồn'),
                textInputAction: TextInputAction.next,
                onSaved: (value) => _title = value!.trim(),
                validator: (value) =>
                    _requiredText(value, 'Vui lòng nhập tiêu đề'),
              ),
              const IncidentFieldTitle('Mô tả chi tiết'),
              TextFormField(
                minLines: 3,
                maxLines: 5,
                onSaved: (value) => _description = value!.trim(),
                decoration: _input(
                  hint: 'Mô tả hiện tượng, các bước dẫn đến lỗi…',
                ),
                validator: (value) =>
                    _requiredText(value, 'Vui lòng mô tả sự cố'),
              ),
              IncidentTimeField(value: _occurredAt, onTap: _chooseTime),
              IncidentPhotoField(
                photo: _photo,
                onPick: _pickingPhotos ? null : _addPhoto,
                onRemove: _pickingPhotos
                    ? null
                    : () => setState(() => _photo = null),
              ),
              if (_isTeacher) ...[
                const SizedBox(height: 16),
                _buildTeachingSupport(),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickingPhotos || _submitting ? null : _submit,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text(_submitting ? 'Đang gửi...' : 'Gửi báo cáo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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

  Widget _buildTeachingSupport() {
    return Material(
      color: _needsTeachingSupport ? const Color(0xFFFFF4F6) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _needsTeachingSupport ? const Color(0xFFEBC2CC) : _line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: const Text(
          'Cần hỗ trợ ngay trong giờ dạy',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Dùng khi sự cố đang ảnh hưởng đến buổi học.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
        value: _needsTeachingSupport,
        onChanged: (value) => setState(() => _needsTeachingSupport = value),
      ),
    );
  }

  Widget _buildType(_IncidentType type) {
    final selected = _type == type;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: () {
          if (selected) return;
          setState(() {
            _type = type;
            _asset = null;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppColors.primary : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black87,
          side: BorderSide(color: selected ? AppColors.primary : _line),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : _pale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type.icon,
                size: 19,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(type.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
