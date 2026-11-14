import "package:flutter/material.dart";
import "package:uth_room_booking/theme/app_theme.dart";
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/core/platform/app_permissions.dart';
import 'package:uth_room_booking/features/technician/data/demo_incident_queue.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _incidentQueue = DemoIncidentQueue();
  late final AppLifecycleListener _lifecycle;
  bool _requestedPermissions = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _requestPermissions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _requestPermissions();
      }
    });
  }

  void _requestPermissions() {
    if (!mounted || _requestedPermissions) return;
    _requestedPermissions = true;
    AppPermissions.requestOnFirstLaunch();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, incidentQueue: _incidentQueue),
    );
  }
}
