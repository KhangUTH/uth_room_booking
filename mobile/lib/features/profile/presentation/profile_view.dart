import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/models/user_role.dart';
import '../../notifications/data/notice_store.dart';
import '../data/profile_contact_store.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/profile_sections.dart';
import 'profile_support_page.dart';

import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

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
    this.noticeStore,
  });

  final String id;
  final UserRole role;
  final Future<void> Function()? onSignOut;
  final String? accountEmail;
  final String? faculty;
  final ProfileContactStore? contactStore;
  final NoticeStore? noticeStore;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _notifications = false;
  bool _savingNotificationPreference = true;
  String _email = '';
  String _phone = '';
  bool _phoneLoaded = false;
  bool _updatingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    if (widget.contactStore != null) _loadPhone();
  }

  String get _notificationPreferenceKey =>
      NoticeStore.pushKey(widget.role.name, widget.id);

  bool get _canSetPush =>
      NoticeStore.supportsPush && widget.noticeStore != null;

  bool get _canChangePush => _canSetPush && !_savingNotificationPreference;

  Future<void> _loadNotificationPreference() async {
    if (!_canSetPush) return;
    try {
      final enabled = await SharedPreferencesAsync().getBool(
        _notificationPreferenceKey,
      );
      if (mounted) setState(() => _notifications = enabled ?? false);
    } catch (_) {
      // Leave notifications disabled when there is no readable preference.
    } finally {
      if (mounted) setState(() => _savingNotificationPreference = false);
    }
  }

  Future<void> _setNotificationPreference(bool enabled) async {
    if (!_canChangePush || enabled == _notifications) return;
    final previous = _notifications;
    setState(() {
      _notifications = enabled;
      _savingNotificationPreference = true;
    });
    var applied = false;
    try {
      applied = await widget.noticeStore?.setPushEnabled(enabled) == true;
      if (!applied) {
        if (mounted) {
          _showProfileError('Hãy cấp quyền thông báo trong cài đặt thiết bị.');
        }
        return;
      }
      await SharedPreferencesAsync().setBool(
        _notificationPreferenceKey,
        enabled,
      );
    } catch (_) {
      if (mounted) _showProfileError('Không lưu được tùy chọn thông báo.');
    } finally {
      if (mounted) {
        setState(() {
          if (!applied) _notifications = previous;
          _savingNotificationPreference = false;
        });
      }
    }
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
        _showProfileError('Không thể đăng xuất. Vui lòng thử lại.');
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
          const Expanded(child: ProfileSectionTitle('Thông tin cá nhân')),
          TextButton.icon(
            onPressed: _updatingProfile ? null : _editProfile,
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Chỉnh sửa'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      ProfileCard(
        rows: [
          _info(Icons.badge_outlined, _idLabel, widget.id),
          if (widget.role != UserRole.technician)
            _info(Icons.apartment_outlined, 'Khoa', widget.faculty ?? ''),
          _info(Icons.mail_outline, 'Email', widget.accountEmail ?? _email),
          _info(Icons.phone_outlined, 'Số điện thoại', _phone),
        ],
      ),
      const SizedBox(height: 16),
      const ProfileSectionTitle('Cài đặt'),
      const SizedBox(height: 8),
      ProfileCard(
        rows: [
          ProfileRow(
            icon: Icons.notifications_none,
            title: 'Nhận thông báo',
            trailing: Switch(
              value: _notifications,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              onChanged: _canChangePush ? _setNotificationPreference : null,
            ),
            onTap: _canChangePush
                ? () => _setNotificationPreference(!_notifications)
                : null,
          ),
          ProfileRow(
            icon: Icons.lock_outline,
            title: 'Đổi mật khẩu',
            onTap: _changePassword,
            trailing: const Icon(
              Icons.chevron_right,
              color: profileMutedColor,
              size: 18,
            ),
          ),
          ProfileRow(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Cài đặt cấp quyền',
            trailing: const Icon(
              Icons.chevron_right,
              color: profileMutedColor,
              size: 18,
            ),
            onTap: () => Navigator.pushNamed(context, AppRoute.appPermissions),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const ProfileSectionTitle('Hỗ trợ'),
      const SizedBox(height: 8),
      ProfileCard(
        rows: [
          _supportAction(Icons.help_outline),
          _supportAction(Icons.description_outlined, terms: true),
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
        style: TextStyle(color: profileMutedColor, fontSize: 11),
      ),
    ],
  );

  Widget _info(IconData icon, String label, String value) => ProfileRow(
    icon: icon,
    title: value.isEmpty ? 'Chưa cập nhật' : value,
    caption: label,
  );

  Future<void> _changePassword() async {
    final store = widget.contactStore;
    if (store == null) {
      _showProfileError('Bạn cần đăng nhập để đổi mật khẩu.');
      return;
    }
    final changed = await showChangePasswordDialog(
      context,
      store.changePassword,
    );
    if (!mounted || changed != true) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu.')));
  }

  Widget _supportAction(IconData icon, {bool terms = false}) => ProfileRow(
    icon: icon,
    title: terms ? ProfileSupportPage.termsTitle : ProfileSupportPage.helpTitle,
    onTap: () => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfileSupportPage(role: widget.role, terms: terms),
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: profileMutedColor,
      size: 18,
    ),
  );
}
