import 'dart:async';

import "package:flutter/material.dart";
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import "package:uth_room_booking/theme/app_theme.dart";
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/core/platform/app_permissions.dart';
import 'package:uth_room_booking/features/auth/presentation/login_page.dart';
import 'package:uth_room_booking/features/technician/data/demo_incident_queue.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oveodjqeffgrfynfudog.supabase.co',
  );
  final sessionStorage = RememberedSessionStorage(Uri.parse(url).host);
  final supabase = await Supabase.initialize(
    httpClient: _SupabaseHttpClient(),
    url: url,
    authOptions: FlutterAuthClientOptions(localStorage: sessionStorage),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_XErseFFdvy439f915bKflw_ZZKEQBFy',
    ),
  );
  runApp(MyApp(supabase: supabase.client, sessionStorage: sessionStorage));
}

class _SupabaseHttpClient extends http.BaseClient {
  final _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final path = request.url.path;
    final signInRequest =
        path.endsWith('/auth/v1/token') ||
        path.endsWith('/auth/v1/logout') ||
        path.endsWith('/functions/v1/sign-in-by-code') ||
        (request.method == 'GET' && path.endsWith('/rest/v1/profiles'));

    if (!signInRequest) return _client.send(request);
    return _readResponse(request).timeout(const Duration(seconds: 10));
  }

  Future<http.StreamedResponse> _readResponse(http.BaseRequest request) async {
    final response = await _client.send(request);
    final body = await response.stream.toBytes();
    return http.StreamedResponse(
      Stream.value(body),
      response.statusCode,
      headers: response.headers,
      request: response.request,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.supabase, this.sessionStorage});

  final SupabaseClient? supabase;
  final RememberedSessionStorage? sessionStorage;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _incidentQueue = DemoIncidentQueue();
  final _navigation = _AppNavigationObserver();
  StreamSubscription<AuthState>? _authSubscription;
  late final AppLifecycleListener _lifecycle;
  bool _requestedPermissions = false;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = widget.supabase?.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.signedOut && state.session == null) {
          _navigation.returnToLogin();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        // Temporary refresh failures keep the app open while the SDK retries.
      },
    );
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = AppLifecycleListener(onResume: _requestPermissions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _requestPermissions();
      }
    });
  }

  @override
  void didChangeMetrics() {
    final keyboardVisible = View.of(context).viewInsets.bottom > 0;
    if (_keyboardVisible && !keyboardVisible) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _keyboardVisible = keyboardVisible;
  }

  void _requestPermissions() {
    if (!mounted || _requestedPermissions) return;
    _requestedPermissions = true;
    AppPermissions.requestOnFirstLaunch();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [_navigation],
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        incidentQueue: _incidentQueue,
        supabase: widget.supabase,
        sessionStorage: widget.sessionStorage,
      ),
    );
  }
}

class _AppNavigationObserver extends NavigatorObserver {
  bool _hasSignedInRoute = false;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    switch (topRoute.settings.name) {
      case AppRoute.home:
        _hasSignedInRoute = true;
      case AppRoute.login:
      case AppRoute.splash:
        _hasSignedInRoute = false;
    }
  }

  void returnToLogin() {
    if (!_hasSignedInRoute) return;
    _hasSignedInRoute = false;
    FocusManager.instance.primaryFocus?.unfocus();
    navigator?.pushNamedAndRemoveUntil<void>(AppRoute.login, (_) => false);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
