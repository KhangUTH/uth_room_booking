import 'package:flutter/material.dart';
import 'package:uth_room_booking/navbar/footer.dart';

const Color _teal = Color(0xFF0E7C7B);

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

  String? _emailError;
  String? _phoneError;

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

  // ---------- kiểm tra dữ liệu ----------
  String? _validateEmail(String v) {
    if (v.isEmpty) return null; // để trống thì cho qua
    final ok = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v);
    return ok ? null : 'Email không hợp lệ';
  }

  String? _validatePhone(String v) {
    if (v.isEmpty) return null;
    // 10 chữ số, bắt đầu bằng 0
    final ok = RegExp(r'^0\d{9}$').hasMatch(v);
    return ok ? null : 'Số điện thoại không hợp lệ';
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade600 : _teal,
          content: Row(
            children: [
              Icon(error ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white),
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

    final emailErr = _validateEmail(email);
    final phoneErr = _validatePhone(phone);

    setState(() {
      _emailError = emailErr;
      _phoneError = phoneErr;
    });

    if (emailErr != null || phoneErr != null) {
      final String msg;
      if (emailErr != null && phoneErr != null) {
        msg = 'Email và số điện thoại không hợp lệ';
      } else if (emailErr != null) {
        msg = 'Email không hợp lệ';
      } else {
        msg = 'Số điện thoại không hợp lệ';
      }
      _showSnack(msg, error: true);
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
    final shownName =
        UserProfileStore.fullName.isNotEmpty ? UserProfileStore.fullName : widget.name;
    final shownId =
        UserProfileStore.studentId.isNotEmpty ? UserProfileStore.studentId : widget.id;

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
                        _field(
                          'Họ và tên',
                          _nameCtrl,
                          onClear: () => setState(_nameCtrl.clear),
                        ),
                        _field(
                          'MSSV',
                          _idCtrl,
                          onClear: () => setState(_idCtrl.clear),
                        ),
                        _field(
                          'Email',
                          _emailCtrl,
                          type: TextInputType.emailAddress,
                          error: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                          onClear: () => setState(() {
                            _emailCtrl.clear();
                            _emailError = null;
                          }),
                        ),
                        _field(
                          'Số điện thoại',
                          _phoneCtrl,
                          type: TextInputType.phone,
                          error: _phoneError,
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                          },
                          onClear: () => setState(() {
                            _phoneCtrl.clear();
                            _phoneError = null;
                          }),
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
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cập Nhật',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
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
    String? error,
    ValueChanged<String>? onChanged,
    required VoidCallback onClear,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                errorText: error,
                errorMaxLines: 2,
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: border(const Color(0xFFD9D9D9)),
                focusedBorder: border(_teal, 1.5),
                errorBorder: border(Colors.red),
                focusedErrorBorder: border(Colors.red, 1.5),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Xóa',
            icon: const Icon(Icons.delete_outline),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

/// Header giống trang "Tôi"
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
        color: _teal,
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