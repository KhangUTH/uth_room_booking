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
import 'package:uth_room_booking/features/booking/presentation/schedule_view.dart';
import 'package:uth_room_booking/features/incident_report/presentation/incident_report_view.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_work_view.dart';
import 'package:uth_room_booking/shared/layouts/bottom_navigation_bar.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

typedef _Account = ({UserRole role, String login, String password});

const _demoPassword = 'uth-lab-test';
const _supaUrl = String.fromEnvironment('TEST_SUPABASE_URL');
const _supaKey = String.fromEnvironment('TEST_SUPABASE_PUBLISHABLE_KEY');
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
}

Future<void> _exerciseRoles(
  WidgetTester tester,
  LoginPage login,
  List<_Account> accounts, {
  SupabaseClient? client,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: login,
      onGenerateRoute: (settings) => settings.name == AppRoute.login
          ? MaterialPageRoute<void>(settings: settings, builder: (_) => login)
          : AppRouter.onGenerateRoute(settings, supabase: client),
    ),
  );

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
      await tester.pump(const Duration(milliseconds: 500));
      final acknowledged = find.text('Đã hiểu');
      if (acknowledged.evaluate().isNotEmpty) await _tap(tester, acknowledged);
      await _tap(tester, _tab('Báo cáo'));
      await _waitFor(tester, find.byType(IncidentReportView));
    }

    await _tap(tester, _tab('Cá nhân'));
    await _tap(tester, find.text('Đăng xuất'));
    await _tap(tester, find.widgetWithText(TextButton, 'Đăng xuất'));
    await _waitFor(tester, find.byType(LoginPage));
    expect(find.byType(MainShell), findsNothing);
  }
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
