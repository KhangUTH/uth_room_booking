import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/demo_incident_queue.dart';
import '../data/technician_incident_store.dart';
import '../models/technician_task.dart';

class TechnicianWorkController extends ChangeNotifier {
  TechnicianWorkController({required this.store, required this.queue});

  final TechnicianIncidentStore? store;
  final DemoIncidentQueue queue;
  late final _sampleJobs = createSampleTechnicianTasks();
  List<TechnicianTask> _liveJobs = [];
  bool _disposed = false;
  bool _loading = false;
  bool _loadFailed = false;
  bool _refreshing = false;
  Timer? _timer;
  int _revision = 0;

  bool get loading => _loading;
  bool get loadFailed => _loadFailed;
  List<TechnicianTask> get jobs =>
      store == null ? [...queue.tasks, ..._sampleJobs] : _liveJobs;

  void start() {
    if (store == null) return;
    unawaited(refresh());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(refresh(silent: true));
      }
    });
  }

  Future<void> refresh({bool silent = false}) async {
    final source = store;
    if (source == null || _disposed || _refreshing) return;
    _refreshing = true;
    _loading = !silent;
    _loadFailed = false;
    if (!silent) notifyListeners();
    try {
      while (!_disposed) {
        final revision = _revision;
        try {
          final jobs = await source.jobs();
          if (_disposed) return;
          if (revision != _revision) continue;
          _liveJobs = jobs;
        } catch (_) {
          if (_disposed) return;
          if (revision != _revision) continue;
          _loadFailed = true;
        }
        break;
      }
    } finally {
      _refreshing = false;
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void taskChanged() {
    if (_disposed) return;
    _revision++;
    if (store == null || _loading) notifyListeners();
    refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
