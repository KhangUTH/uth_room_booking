import 'package:flutter/foundation.dart';

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
  int _revision = 0;

  bool get loading => _loading;
  bool get loadFailed => _loadFailed;
  List<TechnicianTask> get jobs =>
      store == null ? [...queue.tasks, ..._sampleJobs] : _liveJobs;

  Future<void> refresh() async {
    final source = store;
    if (source == null || _disposed || _loading) return;
    _loading = true;
    _loadFailed = false;
    notifyListeners();
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
    _disposed = true;
    super.dispose();
  }
}
