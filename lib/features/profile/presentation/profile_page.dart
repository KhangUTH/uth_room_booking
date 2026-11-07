import "package:flutter/material.dart";
import "package:uth_room_booking/features/auth/presentation/login_page.dart";

import '../models/user_profile.dart';
import 'personal_info_page.dart';

class ProfilePage extends StatelessWidget {
  final String name;
  final String id;
  final bool isTechnician;
  final UserProfile? profile;
  final ValueChanged<UserProfile>? onProfileChanged;
  final ValueChanged<int>? onTabChange;

  const ProfilePage({
    super.key,
    required this.name,
    required this.id,
    this.isTechnician = false,
    this.profile,
    this.onProfileChanged,
    this.onTabChange,
  });

  static const _teal = Color(0xFF0E7C7B);
  static const _cardBg = Color(0xFFF3F3F3);

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label: đang phát triển')));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      // Xóa toàn bộ stack, về lại trang đăng nhập
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Cá nhân'),
                _card([
                  _item(
                    Icons.person_outline,
                    'Thông tin cá nhân',
                    () => Navigator.of(context).push(
                      MaterialPageRoute<UserProfile>(
                        builder: (_) => PersonalInfoPage(
                          name: name,
                          id: id,
                          email: profile?.email ?? '',
                          phone: profile?.phone ?? '',
                          isTechnician: isTechnician,
                          onSaved: onProfileChanged,
                          onTabChange: onTabChange,
                        ),
                      ),
                    ),
                  ),
                  _item(
                    Icons.lock_outline,
                    'Đổi mật khẩu',
                    () => _comingSoon(context, 'Đổi mật khẩu'),
                  ),
                  _item(
                    Icons.notifications_none,
                    'Tùy chỉnh thông báo',
                    () => _comingSoon(context, 'Tùy chỉnh thông báo'),
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Khác'),
                _card([
                  _item(
                    Icons.description_outlined,
                    'Điều khoản sử dụng',
                    () => _comingSoon(context, 'Điều khoản sử dụng'),
                  ),
                  _item(
                    Icons.logout,
                    'Đăng xuất',
                    () => _confirmLogout(context),
                    color: Colors.red,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            '${isTechnician ? 'Tên KTV' : 'Tên SV/GV'}: $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${isTechnician ? 'Mã KTV' : 'Mssv/msgv'}: $id',
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

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: _teal,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: children),
  );

  Widget _item(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
