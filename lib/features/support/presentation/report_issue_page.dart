import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uth_room_booking/features/room/data/sample_rooms.dart';
import 'package:uth_room_booking/features/equipment/data/sample_devices.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/support_request.dart';
import '../widgets/support_widgets.dart';

class ReportIssuePage extends StatefulWidget {
  final ValueChanged<SupportRequest> onSave;
  const ReportIssuePage({super.key, required this.onSave});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String? _type;
  String? _room;
  String? _device;
  Uint8List? _image;
  bool _picking = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null) return;
      if (await file.length() > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn ảnh nhỏ hơn 10 MB.')),
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _image = bytes);
    } on PlatformException {
      _imageError();
    } catch (_) {
      _imageError();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _imageError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể mở ảnh. Vui lòng kiểm tra quyền truy cập hoặc chọn ảnh khác.',
          ),
        ),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      SupportRequest(
        category: 'Báo cáo sự cố',
        fields: {
          'Loại sự cố': _type!,
          'Phòng': _room!,
          if (_type == 'Thiết bị') 'Thiết bị': _device!,
          'Mô tả': _description.text.trim(),
        },
        evidence: _image,
      ),
    );
    showSupportSaved(context);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Thông tin sự cố',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 20),
      SupportPanel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SupportField(
                label: 'Loại sự cố',
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Chọn phòng máy hoặc thiết bị',
                  ),
                  items: ['Phòng máy', 'Thiết bị']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _type = value;
                    _device = null;
                  }),
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn loại sự cố' : null,
                ),
              ),
              SupportField(
                label: 'Chọn phòng máy',
                child: DropdownButtonFormField<String>(
                  initialValue: _room,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'Chọn phòng máy'),
                  items: sampleRooms
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.name,
                          child: Text(r.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _room = value),
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn phòng' : null,
                ),
              ),
              SupportField(
                label: 'Chọn thiết bị',
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_type),
                  initialValue: _device,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: _type == 'Thiết bị'
                        ? 'Chọn thiết bị'
                        : 'Áp dụng cho sự cố thiết bị',
                  ),
                  items: sampleDevices
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.name,
                          child: Text(d.name),
                        ),
                      )
                      .toList(),
                  onChanged: _type == 'Thiết bị'
                      ? (value) => setState(() => _device = value)
                      : null,
                  validator: (value) => _type == 'Thiết bị' && value == null
                      ? 'Vui lòng chọn thiết bị'
                      : null,
                ),
              ),
              SupportField(
                label: 'Mô tả chi tiết sự cố',
                child: TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Mô tả tình trạng sự cố bạn đang gặp phải…',
                  ),
                  validator: requiredSupportText,
                ),
              ),
              SupportField(
                label: 'Hình ảnh minh chứng (nếu có)',
                child: Column(
                  children: [
                    if (_image != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _image!,
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, stack) =>
                              const Text('Không thể hiển thị ảnh này.'),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _image = null),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Xóa ảnh'),
                      ),
                    ],
                    OutlinedButton(
                      onPressed: _picking ? null : _pickImage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _picking ? 'Đang mở thư viện…' : 'Tải hình ảnh lên\nPNG, JPG… · tối đa 10 MB',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _picking ? null : _save,
                  child: const Text('Báo cáo sự cố'),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
