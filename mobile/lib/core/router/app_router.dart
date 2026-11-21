import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_store.dart';
import '../../features/auth/data/remembered_session_storage.dart';
import '../../features/auth/models/user_role.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/booking/data/asset_catalog.dart';
import '../../features/booking/data/booking_store.dart';
import '../../features/equipment/presentation/device_list_page.dart';
import '../../features/incident_report/data/incident_report_store.dart';
import '../../features/notifications/data/notice_store.dart';
import '../../features/notifications/presentation/notifications_view.dart';
import '../../features/profile/data/profile_avatar_storage.dart';
import '../../features/profile/data/profile_contact_store.dart';
import '../../features/profile/presentation/app_permissions_page.dart';
import '../../features/room/presentation/room_list_page.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/technician/data/demo_incident_queue.dart';
import '../../features/technician/data/technician_incident_store.dart';
import '../../features/technician/presentation/task_details_page.dart';
import '../../features/technician/presentation/task_evidence_page.dart';
import '../../shared/layouts/main_shell.dart';
import 'app_route.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(
    RouteSettings settings, {
    DemoIncidentQueue? incidentQueue,
    SupabaseClient? supabase,
    RememberedSessionStorage? sessionStorage,
  }) {
    if (settings.name == AppRoute.home &&
        supabase != null &&
        supabase.auth.currentSession == null) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoute.login),
        builder: (_) =>
            LoginPage(supabase: supabase, sessionStorage: sessionStorage),
      );
    }
    final page = switch ((settings.name, settings.arguments)) {
      (AppRoute.splash, _) => SplashScreen(
        restoreSession: supabase == null
            ? null
            : () => restoreRememberedLogin(supabase),
      ),
      (AppRoute.login, _) => LoginPage(
        supabase: supabase,
        sessionStorage: sessionStorage,
      ),
      (AppRoute.home, HomeRouteArgs args) => MainShell(
        name: args.name,
        id: args.id,
        role: args.role,
        loadCatalog: supabase == null ? null : () => loadAssetCatalog(supabase),
        bookingStore: supabase == null ? null : BookingStore(supabase),
        noticeStore: supabase == null
            ? null
            : NoticeStore(
                supabase,
                pushPreferenceKey: NoticeStore.pushKey(args.role.name, args.id),
              ),
        technicianIncidentStore:
            supabase != null && args.role == UserRole.technician
            ? TechnicianIncidentStore(supabase)
            : null,
        faculty: args.faculty,
        incidentQueue: incidentQueue,
        incidentStore: switch ((supabase, supabase?.auth.currentUser?.id)) {
          (final client?, final userId?) => IncidentReportStore(client, userId),
          _ => null,
        },
        onSignOut: supabase == null
            ? null
            : () => signOutFromApp(supabase, sessionStorage: sessionStorage),
        accountEmail: supabase?.auth.currentUser?.email,
        contactStore: switch ((supabase, supabase?.auth.currentUser?.id)) {
          (final client?, final userId?) => ProfileContactStore(client, userId),
          _ => null,
        },
        avatarStorage: switch ((supabase, supabase?.auth.currentUser?.id)) {
          (final client?, final userId?) => ProfileAvatarStorage(
            client,
            userId,
          ),
          _ => null,
        },
      ),
      (AppRoute.rooms, _) => const RoomListPage(),
      (AppRoute.equipment, _) => const DeviceListPage(),
      (AppRoute.appPermissions, _) => const AppPermissionsPage(),
      (AppRoute.notifications, NotificationsRouteArgs args) =>
        NotificationsView(
          read: args.read,
          saved: args.saved,
          notices: args.notices,
          store: args.store,
          bookingStore: args.bookingStore,
          incidentStore: args.incidentStore,
          technicianStore: args.technicianStore,
          initialNoticeId: args.initialNoticeId,
        ),
      (AppRoute.technicianTask, TechnicianTaskRouteArgs args) =>
        TaskDetailsPage(task: args.task, onChanged: args.onChanged),
      (AppRoute.taskEvidence, TaskEvidenceRouteArgs image) => TaskEvidencePage(
        image: image,
      ),
      _ => const Scaffold(
        body: Center(child: Text('Không thể mở màn hình này.')),
      ),
    };

    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
