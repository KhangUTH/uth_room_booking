import 'package:flutter/material.dart';
import 'package:uth_room_booking/navbar/footer.dart';

/// Nơi lưu tạm thông tin (giữ trong lúc app còn chạy).
/// Sau này thay bằng SharedPreferences hoặc gọi API.
class UserProfileStore {
  static String fullName = '';
  static String studentId = '';
  static String email = '';
  static String phone = '';
}

/// Trang "Thông tin cá nhân"
/// Đặt tại: lib/features/profile/personal_info_page.dart
class PersonalInfoPage extends StatefulWidget {
  final String name;
  final String id;

  /// Gọi khi bấm tab khác ở footer (để HomePage đổi tab).
  final ValueChanged<int>? onTabChange;

  const PersonalInfoPage({
    super.key,
    required this.name,
    required this.id,
    this.onTabChange,
  });

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: UserProfileStore.fullName);
    _idCtrl = TextEditingController(text: UserProfileStore.studentId);
    _emailCtrl = TextEditingController(text: UserProfileStore.email);
    _phoneCtrl = TextEditingController(text: UserProfileStore.phone);
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
          backgroundColor: error ? Colors.red.shade600 : Colors.teal,
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
      UserProfileStore.fullName = _nameCtrl.text.trim();
      UserProfileStore.studentId = _idCtrl.text.trim();
      UserProfileStore.email = email;
      UserProfileStore.phone = phone;
    });

    _showSnack('Thông tin đã được cập nhật thành công');
  }

  @override
  Widget build(BuildContext context) {
    final shownName = UserProfileStore.fullName.isNotEmpty
        ? UserProfileStore.fullName
        : widget.name;
    final shownId = UserProfileStore.studentId.isNotEmpty
        ? UserProfileStore.studentId
        : widget.id;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _Header(name: shownName, id: shownId),
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
                        _field('MSSV', _idCtrl),
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
                        backgroundColor: Colors.teal,
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
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          Navigator.pop(context);
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
                hintText: hint,
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
                  borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Xóa',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(ctrl.clear),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String id;

  const _Header({required this.name, required this.id});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topInset + 24, 16, 36),
      decoration: BoxDecoration(
        color: const Color(0xFF0E7C7B),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.elliptical(width / 2, 60),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person_outline, size: 44, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            'Tên SV/GV: $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Mssv/msgv: $id',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
