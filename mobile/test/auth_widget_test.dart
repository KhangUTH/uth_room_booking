import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/auth/data/auth_store.dart';
import 'package:uth_room_booking/features/auth/data/remembered_session_storage.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/features/auth/presentation/login_page.dart';
import 'package:uth_room_booking/features/auth/widgets/technician_login_sheet.dart';
import 'package:uth_room_booking/features/splash/presentation/splash_screen.dart';
import 'package:uth_room_booking/features/technician/data/demo_incident_queue.dart';
import 'package:uth_room_booking/features/technician/widgets/technician_task_card.dart';
import 'package:uth_room_booking/main.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

import 'support/widget_test_helpers.dart';

final _testSession = Session(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  tokenType: 'bearer',
  user: const User(
    id: 'test-user',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '',
  ),
);

Future<HomeRouteArgs> _testAuthenticate(
  String identifier,
  String password,
  UserRole role,
) async {
  if (password != 'mat-khau-demo') {
    throw const AuthException('Thông tin đăng nhập không đúng.');
  }
  return (
    name: 'Tài khoản kiểm thử',
    id: identifier,
    role: role,
    faculty: null,
  );
}

Widget _loginApp({bool useTestAuthentication = true}) {
  final incidentQueue = DemoIncidentQueue();
  final login = useTestAuthentication
      ? const LoginPage.withTestAuthentication(authenticate: _testAuthenticate)
      : const LoginPage();
  return MaterialApp(
    theme: AppTheme.light,
    home: login,
    onGenerateRoute: (settings) {
      if (settings.name == AppRoute.login) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => login,
        );
      }
      return AppRouter.onGenerateRoute(settings, incidentQueue: incidentQueue);
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'OTP khôi phục xác minh trước khi đổi mật khẩu và không tạo phiên app',
    () async {
      const email = 'recovery@example.com';
      final paths = <String>[];
      final httpClient = MockClient((request) async {
        paths.add(request.url.path);
        final body = request.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(request.body) as Map<String, dynamic>;
        switch (request.url.path) {
          case '/auth/v1/recover':
            expect(body['email'], email);
            return http.Response('{}', 200);
          case '/auth/v1/verify':
            expect(body['type'], 'recovery');
            expect(body['email'], email);
            if (body['token'] != '123456') {
              return http.Response(
                '{"code":"otp_expired","message":"Invalid code"}',
                403,
              );
            }
            return http.Response(jsonEncode(_testSession.toJson()), 200);
          case '/auth/v1/user':
            expect(
              request.headers['authorization'],
              'Bearer test-access-token',
            );
            expect(body['password'], 'Mat-khau-thu-2026');
            return http.Response(jsonEncode(_testSession.user.toJson()), 200);
          case '/auth/v1/logout':
            return http.Response('', 204);
          default:
            fail('Unexpected request: ${request.url.path}');
        }
      });
      final client = SupabaseClient(
        'https://example.com',
        'sb_publishable_example',
      );
      addTearDown(client.dispose);
      final recovery = PasswordRecovery(client, httpClient: httpClient);

      await recovery.sendCode(email);
      await expectLater(
        recovery.verifyCode(email, '000000'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        recovery.updatePassword('Mat-khau-thu-2026'),
        throwsStateError,
      );
      await recovery.verifyCode(email, '123456');
      expect(client.auth.currentSession, isNull);
      await recovery.updatePassword('Mat-khau-thu-2026');
      await recovery.close();
      expect(paths, [
        '/auth/v1/recover',
        '/auth/v1/verify',
        '/auth/v1/verify',
        '/auth/v1/user',
        '/auth/v1/logout',
      ]);
    },
  );

  test('chỉ lưu phiên khi người dùng chọn ghi nhớ', () async {
    SharedPreferences.setMockInitialValues({'sb-example-auth-token': 'old'});
    FlutterSecureStorage.setMockInitialValues({});
    final storage = RememberedSessionStorage('example.com');
    await storage.initialize();
    final legacy = await SharedPreferences.getInstance();
    expect(legacy.containsKey('sb-example-auth-token'), isFalse);

    await storage.persistSession('ignored');
    expect(await const FlutterSecureStorage().readAll(), isEmpty);

    await storage.remember(_testSession);
    await storage.persistSession('refreshed');
    final reopened = RememberedSessionStorage('example.com');
    await reopened.initialize();
    expect(await reopened.accessToken(), 'refreshed');

    await reopened.removePersistedSession();
    await reopened.persistSession('ignored');
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  testWidgets('mất phiên đóng màn hình con và quay về đăng nhập', (
    tester,
  ) async {
    await useMobileScreen(tester);
    final client = (await tester.runAsync(() async {
      final client = SupabaseClient(
        'https://example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (request) async => request.url.path.endsWith('/logout')
              ? http.Response('', 204)
              : http.Response('{"message":"Not found"}', 404),
        ),
      );
      await client.auth.recoverSession(jsonEncode(_testSession));
      return client;
    }))!;
    addTearDown(() => tester.runAsync(client.dispose));

    await tester.pumpWidget(MyApp(supabase: client));
    final navigator = Navigator.of(tester.element(find.byType(SplashScreen)));
    unawaited(
      navigator.pushReplacementNamed<void, void>(
        AppRoute.home,
        arguments: (
          name: 'Sinh viên kiểm thử',
          id: 'SV01',
          role: UserRole.student,
          faculty: null,
        ) as HomeRouteArgs,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    unawaited(navigator.pushNamed<void>(AppRoute.equipment));
    await tester.pumpAndSettle();

    await client.auth.signOut(scope: SignOutScope.local);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoginPage), findsOneWidget);
    expect(navigator.canPop(), isFalse);
    await unmountApp(tester);
  });

  testWidgets('không đóng bảng kỹ thuật viên khi đang xác thực', (
    tester,
  ) async {
    await useMobileScreen(tester);
    final authentication = Completer<HomeRouteArgs>();
    HomeRouteArgs? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTechnicianLoginSheet(
                  context,
                  authenticate: (_, _, _) => authentication.future,
                );
              },
              child: const Text('Mở đăng nhập'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở đăng nhập'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'KT01');
    await tester.enterText(fields.last, 'mat-khau-demo');
    final submit = find.text('Đăng nhập');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(TechnicianLoginSheet), findsOneWidget);
    expect(result, isNull);

    authentication.complete((
      name: 'Kỹ thuật viên',
      id: 'KT01',
      role: UserRole.technician,
      faculty: null,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(TechnicianLoginSheet), findsNothing);
    expect(result?.role, UserRole.technician);
  });

  test(
    'đăng nhập bằng email gửi qua Edge Function và hiển thị giới hạn',
    () async {
      final client = SupabaseClient(
        'https://example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          expect(request.url.path, endsWith('/functions/v1/sign-in-by-code'));
          expect(jsonDecode(request.body), {
            'email': 'student@example.com',
            'password': 'test-only',
            'role': 'student',
          });
          return http.Response(
            '{"code":"over_request_rate_limit"}',
            429,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await expectLater(
        authenticateWithSupabase(
          client,
          null,
          'student@example.com',
          'test-only',
          UserRole.student,
          false,
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            'Bạn thử đăng nhập lại sau ít phút.',
          ),
        ),
      );
    },
  );

  testWidgets('mất mạng hiện lỗi trong form và cho phép thử lại', (
    tester,
  ) async {
    await useMobileScreen(tester);
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          throw http.ClientException('Network unavailable', request.url);
        }),
      ),
    ))!;
    addTearDown(() => tester.runAsync(client.dispose));
    await tester.pumpWidget(MaterialApp(home: LoginPage(supabase: client)));
    final fields = find.byType(TextFormField);
    final button = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    await tester.enterText(fields.last, 'mat-khau-demo');
    for (final identifier in ['12345', 'student@example.com']) {
      await tester.enterText(fields.first, identifier);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Không thể kết nối. Kiểm tra mạng rồi thử lại.'),
        findsOneWidget,
        reason: 'Kiểm tra khi đăng nhập bằng $identifier',
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
      expect(find.text(identifier), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('Splash', () {
    testWidgets('logo và hình trường nằm gọn khi đổi kích thước màn hình', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const screen = MaterialApp(home: SplashScreen());
      Finder artwork(String path) => find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.endsWith(path),
      );
      for (final size in const [
        Size(320, 568),
        Size(568, 320),
        Size(800, 1280),
        Size(1280, 800),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(screen);
        final logo = tester.getRect(artwork('logo.jpg'));
        final school = tester.getRect(artwork('splash_school.jpg'));
        final bounds = Offset.zero & size;
        for (final rect in [logo, school]) {
          expect(rect.left, greaterThanOrEqualTo(bounds.left));
          expect(rect.top, greaterThanOrEqualTo(bounds.top));
          expect(rect.right, lessThanOrEqualTo(bounds.right));
          expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
        }
        expect(logo.overlaps(school), isFalse);
        expect(tester.takeException(), isNull);
      }
      await unmountApp(tester);
    });

    testWidgets('mở đúng Trang chủ khi khôi phục được hồ sơ', (tester) async {
      await useMobileScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            restoreSession: () async => (
              name: 'Giảng viên kiểm thử',
              id: 'GV01',
              role: UserRole.teacher,
              faculty: 'Công nghệ thông tin',
            ),
          ),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Xin chào, Giảng viên'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('application starts on the splash screen', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      // Đẩy thời gian qua để các Timer/Future.delayed của splash chạy xong,
      // tránh lỗi "A Timer is still pending" khi test kết thúc.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LoginPage), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('LoginPage', () {
    testWidgets('ô mô tả giữ focus khi chiều cao bàn phím thay đổi', (
      tester,
    ) async {
      await useMobileScreen(tester);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));

      final navigator = Navigator.of(tester.element(find.byType(LoginPage)));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const MainShell(name: 'Sinh viên', id: 'SV01'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      final description = find.byType(TextFormField).last;
      await tester.ensureVisible(description);
      await tester.tap(description);
      await tester.pumpAndSettle();
      final editable = tester.widget<EditableText>(
        find.descendant(of: description, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pump();
      expect(editable.focusNode.hasFocus, isTrue);
      await unmountApp(tester);
    });

    testWidgets('sinh viên xem lại báo cáo đang xử lý sau khi đổi tài khoản', (
      tester,
    ) async {
      await useMobileScreen(tester);
      await tester.pumpWidget(_loginApp());

      Future<void> login(String id) async {
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(fields.evaluate().length - 2), id);
        await tester.enterText(fields.last, 'mat-khau-demo');
        final button = find.widgetWithText(ElevatedButton, 'Đăng nhập').last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      Future<void> logout() async {
        await tester.tap(find.text('Cá nhân'));
        await tester.pumpAndSettle();
        final button = find.text('Đăng xuất');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      await login('21110234');
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng A101').last);
      await tester.pumpAndSettle();
      const title = 'Máy phòng A101 bị lỗi';
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, title);
      await tester.enterText(fields.at(1), 'Không mở được máy');
      final submit = find.text('Gửi báo cáo');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await logout();

      final technicianLogin = find.text('Cổng dành cho kỹ thuật viên');
      await tester.ensureVisible(technicianLogin);
      await tester.tap(technicianLogin);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await login('KT-0217');
      await tester.tap(find.text('Công việc'));
      await tester.pumpAndSettle();
      final card = find.widgetWithText(TechnicianTaskCard, title);
      await tester.ensureVisible(card);
      await tester.tap(
        find.descendant(of: card, matching: find.text('Nhận việc')),
      );
      await tester.pumpAndSettle();
      await logout();

      await login('21110234@ut.edu.vn');
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.text('Đang xử lý'), findsOneWidget);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text('Không mở được máy'), findsOneWidget);
      expect(find.textContaining('Đang xử lý lúc'), findsOneWidget);
    });

    testWidgets('đăng nhập và đăng xuất thay thế route hiện tại', (
      tester,
    ) async {
      await useMobileScreen(tester);
      await tester.pumpWidget(_loginApp());
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '21110234');
      await tester.enterText(fields.at(1), 'mat-khau-demo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('MSSV: 21110234'), findsOneWidget);
      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      final logout = find.text('Đăng xuất');
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
        isFalse,
      );
      await unmountApp(tester);
    });
    testWidgets('hiển thị tab, form và mặc định là Sinh viên', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      // 'Sinh viên' xuất hiện ở tab và ở tiêu đề form.
      expect(find.text('Sinh viên'), findsNWidgets(2));
      expect(find.text('Giảng viên'), findsOneWidget); // chỉ ở tab
      expect(find.text('Mã sinh viên / Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('bấm tab Giảng viên thì đổi nhãn và tiêu đề', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      await tester.tap(find.text('Giảng viên'));
      // Chờ AnimatedSwitcher (450ms) chạy xong.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Giảng viên'), findsNWidgets(2)); // tab + tiêu đề
      expect(find.text('Mã giảng viên / Email'), findsOneWidget);
      expect(find.text('Mã sinh viên / Email'), findsNothing);

      await unmountApp(tester);
    });

    testWidgets('thiếu cấu hình xác thực thì không vào Trang chủ', (
      tester,
    ) async {
      await useMobileScreen(tester);
      await tester.pumpWidget(_loginApp(useTestAuthentication: false));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '21110234');
      await tester.enterText(fields.last, 'mat-khau-demo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Chưa cấu hình hệ thống đăng nhập.'), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('để trống rồi đăng nhập thì báo lỗi', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();

      expect(find.text('Vui lòng nhập mã sinh viên'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);

      await unmountApp(tester);
    });
  });
}
