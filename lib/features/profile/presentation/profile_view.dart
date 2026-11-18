import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../data/profile_contact_store.dart';
import '../widgets/app_permission_settings.dart';
import '../widgets/edit_profile_dialog.dart';

import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);
const _red = Color(0xFFCB313B);

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.id,
    required this.role,
    this.onSignOut,
    this.accountEmail,
    this.faculty,
    this.contactStore,
  });

  final String id;
  final UserRole role;
  final Future<void> Function()? onSignOut;
  final String? accountEmail;
  final String? faculty;
  final ProfileContactStore? contactStore;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _notifications = true;
  bool _noticeVisible = false;
  String _email = '';
  String _phone = '';
  bool _phoneLoaded = false;
  bool _updatingProfile = false;

  @override
  void initState() {
    super.initState();
    if (widget.contactStore != null) _loadPhone();
  }

  Future<bool> _loadPhone() async {
    final store = widget.contactStore;
    if (store == null) return true;
    setState(() => _updatingProfile = true);
    try {
      final phone = await store.loadPhone();
      if (!mounted) return false;
      setState(() {
        _phone = phone;
        _phoneLoaded = true;
      });
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _updatingProfile = false);
    }
  }

  void _showProfileError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String get _idLabel => switch (widget.role) {
    UserRole.student => 'Mã số sinh viên',
    UserRole.teacher => 'Mã giảng viên',
    UserRole.technician => 'Mã nhân viên',
  };

  Future<void> _editProfile() async {
    if (!_phoneLoaded && !await _loadPhone()) {
      if (mounted) {
        _showProfileError('Không tải được số điện thoại. Vui lòng thử lại.');
      }
      return;
    }
    if (!mounted) return;
    final store = widget.contactStore;
    final changes = await showEditProfileDialog(
      context,
      initialEmail: widget.accountEmail ?? _email,
      initialPhone: _phone,
      emailReadOnly: widget.accountEmail != null,
      onSavePhone: store?.savePhone,
    );
    if (changes == null || !mounted) return;
    setState(() {
      _email = changes.email;
      _phone = changes.phone;
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.onSignOut?.call();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đăng xuất. Vui lòng thử lại.'),
          ),
        );
      }
      return;
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil<void>(AppRoute.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
    children: [
      Row(
        children: [
          const Expanded(child: _SectionTitle('Thông tin cá nhân')),
          TextButton.icon(
            onPressed: _updatingProfile ? null : _editProfile,
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Chỉnh sửa'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      _ProfileCard(
        rows: [
          _info(Icons.badge_outlined, _idLabel, widget.id),
          if (widget.role != UserRole.technician)
            _info(Icons.apartment_outlined, 'Khoa', widget.faculty ?? ''),
          _info(Icons.mail_outline, 'Email', widget.accountEmail ?? _email),
          _info(Icons.phone_outlined, 'Số điện thoại', _phone),
        ],
      ),
      const SizedBox(height: 16),
      const _SectionTitle('Cài đặt'),
      const SizedBox(height: 8),
      _ProfileCard(
        rows: [
          _ProfileRow(
            icon: Icons.notifications_none,
            title: 'Nhận thông báo',
            trailing: Switch(
              value: _notifications,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              onChanged: (value) => setState(() => _notifications = value),
            ),
            onTap: () => setState(() => _notifications = !_notifications),
          ),
          _action(Icons.lock_outline, 'Đổi mật khẩu'),
          _ProfileRow(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Cài đặt cấp quyền',
            trailing: const Icon(Icons.chevron_right, color: _muted, size: 18),
            onTap: () => openAppPermissionSettings(context),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const _SectionTitle('Hỗ trợ'),
      const SizedBox(height: 8),
      _ProfileCard(
        rows: [
          _action(Icons.help_outline, 'Trung tâm trợ giúp'),
          _action(Icons.description_outlined, 'Điều khoản sử dụng'),
        ],
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, size: 17),
        label: const Text('Đăng xuất'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _red,
          side: const BorderSide(color: _red),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Phiên bản 1.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontSize: 11),
      ),
    ],
  );

  Widget _info(IconData icon, String label, String value) => _ProfileRow(
    icon: icon,
    title: value.isEmpty ? 'Chưa cập nhật' : value,
    caption: label,
  );

  Future<void> _showDevelopmentNotice() async {
    if (_noticeVisible) return;
    _noticeVisible = true;
    try {
      await ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(content: Text('Tính năng đang phát triển.')),
          )
          .closed;
    } finally {
      _noticeVisible = false;
    }
  }

  Widget _action(IconData icon, String title) => _ProfileRow(
    icon: icon,
    title: title,
    onTap: _showDevelopmentNotice,
    trailing: const Icon(Icons.chevron_right, color: _muted, size: 18),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: const BorderSide(color: _line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const Divider(height: 1, thickness: 1, color: _line),
          rows[index],
        ],
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    this.caption,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _pale,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (caption case final label?)
                    Text(
                      label,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  Text(title, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (trailing case final widget?) ...[
              const SizedBox(width: 8),
              widget,
            ],
          ],
        ),
      ),
    ),
  );
}
