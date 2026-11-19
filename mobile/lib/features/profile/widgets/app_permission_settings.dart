import 'package:flutter/material.dart';

import '../../../core/platform/app_permissions.dart';

Future<void> openAppPermissionSettings(BuildContext context) async {
  if (await AppPermissions.openSettings()) return;

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Hãy mở Cài đặt trên thiết bị và chọn ứng dụng để quản lý quyền.',
      ),
    ),
  );
}
