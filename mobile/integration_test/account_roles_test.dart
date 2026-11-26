import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/features/auth/presentation/login_page.dart';
import 'package:uth_room_booking/features/auth/widgets/academic_login_form.dart';
import 'package:uth_room_booking/features/auth/widgets/technician_login_sheet.dart';
import 'package:uth_room_booking/features/booking/data/booking_store.dart';
import 'package:uth_room_booking/features/booking/models/booking.dart';
import 'package:uth_room_booking/features/booking/presentation/schedule_view.dart';
import 'package:uth_room_booking/features/booking/widgets/booking_history_card.dart';
import 'package:uth_room_booking/features/incident_report/presentation/incident_report_view.dart';
import 'package:uth_room_booking/features/profile/presentation/profile_view.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_work_view.dart';
import 'package:uth_room_booking/shared/layouts/bottom_navigation_bar.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

typedef _Account = ({UserRole role, String login, String password});

const _demoPassword = 'uth-lab-test';
const _supaUrl = String.fromEnvironment('TEST_SUPABASE_URL');
const _supaKey = String.fromEnvironment('TEST_SUPABASE_PUBLISHABLE_KEY');
const _adminEmail = String.fromEnvironment('TEST_ADMIN_EMAIL');
const _adminPassword = String.fromEnvironment('TEST_ADMIN_PASSWORD');
const _allowTestWrites = bool.fromEnvironment('TEST_ALLOW_WRITES');
const _liveAccounts = <_Account>[
  (
    role: UserRole.student,
    login: String.fromEnvironment('TEST_STUDENT_LOGIN'),
    password: String.fromEnvironment('TEST_STUDENT_PASSWORD'),
  ),
  (
    role: UserRole.teacher,
    login: String.fromEnvironment('TEST_TEACHER_LOGIN'),
    password: String.fromEnvironment('TEST_TEACHER_PASSWORD'),
  ),
  (
    role: UserRole.technician,
    login: String.fromEnvironment('TEST_TECHNICIAN_LOGIN'),
    password: String.fromEnvironment('TEST_TECHNICIAN_PASSWORD'),
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android: mở đúng màn hình và đổi tài khoản theo ba vai trò', (
    tester,
  ) async {
    const accounts = <_Account>[
      (role: UserRole.student, login: 'SV-TEST-01', password: _demoPassword),
      (role: UserRole.teacher, login: 'GV-TEST-01', password: _demoPassword),
      (role: UserRole.technician, login: 'KT-TEST-01', password: _demoPassword),
    ];
    final login = LoginPage.withTestAuthentication(
      authenticate: (identifier, password, role) async {
        final fixture = accounts.singleWhere((account) => account.role == role);
        if (fixture.login != identifier || fixture.password != password) {
          throw const AuthException('Sai thông tin kiểm thử.');
        }
        return (
          name: 'Tài khoản kiểm thử',
          id: fixture.login,
          role: role,
          faculty: null,
        );
      },
    );
    await _exerciseRoles(tester, login, accounts);
  });

  testWidgets(
    'Supabase: đăng nhập thật theo ba vai trò và mở các tab chính',
    (tester) async {
      final client = SupabaseClient(_supaUrl, _supaKey);
      try {
        await _exerciseRoles(
          tester,
          LoginPage(supabase: client),
          _liveAccounts,
          client: client,
        );
        expect(client.auth.currentSession, isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await client.dispose();
      }
    },
    skip:
        _supaUrl.isEmpty ||
        _supaKey.isEmpty ||
        _liveAccounts.any((a) => a.login.isEmpty || a.password.isEmpty),
  );

  for (final (decision, fixtureId) in [
    ('approved', const String.fromEnvironment('TEST_APPROVE_BOOKING_ID')),
    ('rejected', const String.fromEnvironment('TEST_REJECT_BOOKING_ID')),
  ]) {
    final student = _liveAccounts.first;
    testWidgets(
      'Supabase: Lịch tự cập nhật khi admin chuyển đơn sang $decision',
      (tester) async {
        final client = SupabaseClient(_supaUrl, _supaKey);
        final admin = SupabaseClient(_supaUrl, _supaKey);
        try {
          await _mountLogin(tester, LoginPage(supabase: client), client);
          await _signIn(tester, student);
          final booking = await BookingStore(client).bookingById(fixtureId);
          expect(
            booking,
            isNotNull,
            reason: 'Đơn phải thuộc sinh viên thử nghiệm.',
          );
          expect(booking!.status, BookingStatus.pending);
          await _tap(tester, _tab('Lịch'));
          await _waitFor(tester, find.byType(ScheduleView));
          await _dismissBookingHint(tester);
          await _tap(tester, find.text('Của tôi'));
          await _tap(tester, find.text('Tất cả ngày'));

          Finder cardWith(BookingStatus status) => find.byWidgetPredicate(
            (widget) =>
                widget is BookingHistoryCard &&
                widget.booking.slot == booking.slot &&
                widget.booking.status == status,
          );
          await _waitFor(tester, cardWith(BookingStatus.pending));
          await admin.auth.signInWithPassword(
            email: _adminEmail,
            password: _adminPassword,
          );
          await admin.rpc<void>(
            'uth_admin_decide_booking',
            params: {'booking_id': fixtureId, 'decision': decision},
          );
          await _waitFor(
            tester,
            cardWith(BookingStatus.values.byName(decision)),
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await client.dispose();
          await admin.dispose();
        }
      },
      skip:
          !_allowTestWrites ||
          [
            _supaUrl,
            _supaKey,
            _adminEmail,
            _adminPassword,
            fixtureId,
            student.login,
            student.password,
          ].any((value) => value.isEmpty),
    );
  }
}

Future<void> _exerciseRoles(
  WidgetTester tester,
  LoginPage login,
  List<_Account> accounts, {
  SupabaseClient? client,
}) async {
  await _mountLogin(tester, login, client);

  for (final account in accounts) {
    await _signIn(tester, account);
    final shell = tester.widget<MainShell>(find.byType(MainShell));
    expect(shell.role, account.role);

    if (account.role == UserRole.technician) {
      expect(_tab('Lịch'), findsNothing);
      expect(_tab('Báo cáo'), findsNothing);
      await _tap(tester, _tab('Công việc'));
      expect(find.byType(TechnicianWorkView), findsOneWidget);
    } else {
      expect(_tab('Công việc'), findsNothing);
      await _tap(tester, _tab('Lịch'));
      await _waitFor(tester, find.byType(ScheduleView));
      await _dismissBookingHint(tester);
      await _tap(tester, _tab('Báo cáo'));
      await _waitFor(tester, find.byType(IncidentReportView));
    }

    await _tap(tester, _tab('Cá nhân'));
    final logout = find.widgetWithText(OutlinedButton, 'Đăng xuất');
    await tester.scrollUntilVisible(
      logout,
      200,
      scrollable: find.descendant(
        of: find.byType(ProfileView),
        matching: find.byType(Scrollable),
      ),
    );
    await _tap(tester, logout);
    await _tap(tester, find.widgetWithText(TextButton, 'Đăng xuất'));
    await _waitFor(tester, find.byType(LoginPage));
    expect(find.byType(MainShell), findsNothing);
  }
}

Future<void> _mountLogin(
  WidgetTester tester,
  LoginPage login,
  SupabaseClient? client,
) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: login,
    onGenerateRoute: (settings) => settings.name == AppRoute.login
        ? MaterialPageRoute<void>(settings: settings, builder: (_) => login)
        : AppRouter.onGenerateRoute(settings, supabase: client),
  ),
);

Future<void> _dismissBookingHint(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  final acknowledged = find.text('Đã hiểu');
  if (acknowledged.evaluate().isNotEmpty) await _tap(tester, acknowledged);
}

Finder _tab(String label) => find.descendant(
  of: find.byType(AppBottomNavigationBar),
  matching: find.text(label),
);

Future<void> _signIn(WidgetTester tester, _Account account) async {
  if (account.role == UserRole.teacher) {
    await _tap(tester, find.text('Giảng viên'));
  } else if (account.role == UserRole.technician) {
    await _tap(tester, find.text('Cổng dành cho kỹ thuật viên'));
    await _waitFor(tester, find.byType(TechnicianLoginSheet));
  }
  final form = find.byType(
    account.role == UserRole.technician
        ? TechnicianLoginSheet
        : AcademicLoginForm,
  );
  final fields = find.descendant(
    of: form,
    matching: find.byType(TextFormField),
  );
  await tester.enterText(fields.at(0), account.login);
  await tester.enterText(fields.at(1), account.password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 350));
  await _tap(
    tester,
    find.descendant(of: form, matching: find.text('Đăng nhập')),
  );
  await _waitFor(tester, find.byType(MainShell));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsOneWidget);
  await tester.pump(const Duration(milliseconds: 350));
}
