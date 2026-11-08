import 'package:uth_room_booking/shared/layouts/header.dart';
import 'package:flutter/material.dart';
import 'package:uth_room_booking/shared/layouts/footer.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/user_profile.dart';

/// Trang "Thông tin cá nhân"
class PersonalInfoPage extends StatefulWidget {
  final String name;
  final String id;
  final String email;
  final String phone;
  final bool isTechnician;
  final ValueChanged<UserProfile>? onSaved;

  /// Gọi khi bấm tab khác ở footer (để HomePage đổi tab).
  final ValueChanged<int>? onTabChange;

  const PersonalInfoPage({
    super.key,
    required this.name,
    required this.id,
    this.onTabChange,
    this.email = '',
    this.phone = '',
    this.isTechnician = false,
    this.onSaved,
  });

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = UserProfile(
      fullName: widget.name,
      id: widget.id,
      email: widget.email,
      phone: widget.phone,
    );
    _nameCtrl = TextEditingController(text: widget.name);
    _idCtrl = TextEditingController(text: widget.id);
    _emailCtrl = TextEditingController(text: widget.email);
    _phoneCtrl = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade600 : AppColors.primary,
          content: Row(
            children: [
              Icon(
                error ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (_nameCtrl.text.trim().isEmpty || _idCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập họ tên và mã định danh', error: true);
      return;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnack('Email không hợp lệ', error: true);
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^\d{9,11}$').hasMatch(phone)) {
      _showSnack('Số điện thoại không hợp lệ', error: true);
      return;
    }

    setState(() {
      _profile = UserProfile(
        fullName: _nameCtrl.text.trim(),
        id: _idCtrl.text.trim(),
        email: email,
        phone: phone,
      );
    });
    widget.onSaved?.call(_profile);
    _showSnack('Đã cập nhật thông tin trong phiên chạy');
  }

  @override
  Widget build(BuildContext context) {
    final shownName = _profile.fullName;
    final shownId = _profile.id;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyHeader(
            name: shownName,
            id: shownId,
            isTechnician: widget.isTechnician,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  const Text(
                    'THÔNG TIN CÁ NHÂN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _field('Họ và tên', _nameCtrl),
                        _field(
                          widget.isTechnician ? 'Mã KTV' : 'MSSV/MSGV',
                          _idCtrl,
                        ),
                        _field(
                          'Email',
                          _emailCtrl,
                          type: TextInputType.emailAddress,
                        ),
                        _field(
                          'Số điện thoại',
                          _phoneCtrl,
                          type: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cập Nhật',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyFooter(
        currentIndex: widget.isTechnician ? 2 : 3,
        isTechnician: widget.isTechnician,
        onTap: (i) {
          if (i == (widget.isTechnician ? 2 : 3)) return;
          Navigator.pop(context, _profile);
          widget.onTabChange?.call(i);
        },
      ),
    );
  }

  /// 1 dòng: ô nhập + nút thùng rác (xóa nội dung ô đó)
  Widget _field(
    String hint,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              decoration: InputDecoration(
                labelText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Xóa $hint',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(ctrl.clear),
          ),
        ],
      ),
    );
  }
}
