import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/widgets/pill_tabs.dart';
import '../../auth/models/user_role.dart';
import '../../technician/data/demo_incident_queue.dart';
import '../data/incident_report_store.dart';
import '../models/incident_report.dart';
import '../widgets/incident_report_details_sheet.dart';
import '../widgets/incident_report_form.dart';
import '../widgets/incident_report_history.dart';

class IncidentReportView extends StatefulWidget {
  const IncidentReportView({
    super.key,
    required this.name,
    required this.id,
    required this.role,
    required this.queue,
    this.avatar,
    this.roomNames,
    this.equipmentNames,
    this.store,
    this.active = true,
  });

  final String name;
  final String id;
  final UserRole role;
  final DemoIncidentQueue queue;
  final ImageProvider? avatar;
  final Iterable<String>? roomNames;
  final Iterable<String>? equipmentNames;
  final IncidentReportStore? store;
  final bool active;

  @override
  State<IncidentReportView> createState() => _IncidentReportViewState();
}

class _IncidentReportViewState extends State<IncidentReportView> {
  ReportOwner get _owner => demoReportOwner(widget.role, widget.id);
  late bool _showHistory =
      widget.store == null && widget.queue.reportsFor(_owner).isNotEmpty;
  final _reports = <int, StoredIncidentReport>{};
  String? _submissionId;
  String? _historyMessage;
  bool _loadingHistory = false;
  int _historyRequest = 0;
  IncidentAssets? _assets;
  List<String>? _courseSections;
  bool _loadingAssets = false;
  String? _assetsMessage;

  @override
  void initState() {
    super.initState();
    if (widget.active) _loadAssets();
  }

  Future<void> _loadAssets() async {
    final store = widget.store;
    if (store == null || _loadingAssets || _assets != null) return;
    setState(() {
      _loadingAssets = true;
      _assetsMessage = null;
    });
    try {
      final assets = await store.assets();
      final courses = widget.role == UserRole.teacher
          ? await store.teachingSections()
          : null;
      if (mounted) {
        setState(() {
          _assets = assets;
          _courseSections = courses;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _assetsMessage = 'Không tải được danh mục. Thử lại');
      }
    } finally {
      if (mounted) setState(() => _loadingAssets = false);
    }
  }

  @override
  void didUpdateWidget(covariant IncidentReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _loadAssets();
    if (widget.active && !oldWidget.active && _showHistory) _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    final store = widget.store;
    if (store == null) return;
    final request = ++_historyRequest;
    setState(() {
      _loadingHistory = true;
      _historyMessage = null;
    });
    try {
      final reports = await store.history();
      if (!mounted || request != _historyRequest) return;
      setState(() {
        _reports
          ..clear()
          ..addEntries(reports.map((item) => MapEntry(item.report.id, item)));
      });
    } catch (_) {
      if (mounted && request == _historyRequest) {
        setState(() => _historyMessage = 'Không tải được báo cáo. Thử lại.');
      }
    } finally {
      if (mounted && request == _historyRequest) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  void _remember(StoredIncidentReport item) {
    _historyRequest++;
    _loadingHistory = false;
    _historyMessage = null;
    final id = item.report.id;
    if (_reports.containsKey(id)) {
      _reports[id] = item;
      return;
    }
    final previous = Map<int, StoredIncidentReport>.of(_reports);
    _reports
      ..clear()
      ..[id] = item
      ..addAll(previous);
  }

  Future<bool> _submit(IncidentReport report) async {
    final store = widget.store;
    if (store != null) {
      final id = _submissionId ??= store.newSubmissionId();
      final StoredIncidentReport saved;
      try {
        saved = await store.submit(id, report);
      } on FormatException {
        rethrow;
      } catch (_) {
        return false;
      }
      if (!mounted) return true;
      setState(() {
        _submissionId = null;
        _remember(saved);
        _showHistory = true;
      });
      if (widget.active) _showReport(saved.report);
      _refreshHistory();
      return true;
    }
    setState(() {
      widget.queue.submit(_owner, report, widget.name);
      _showHistory = true;
    });
    _showReport(report);
    return true;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: PillTabs<bool>(
          options: const {false: 'Tạo báo cáo', true: 'Báo cáo của tôi'},
          selected: _showHistory,
          onSelected: (showHistory) {
            if (_showHistory == showHistory) return;
            FocusScope.of(context).unfocus();
            setState(() => _showHistory = showHistory);
            if (showHistory) _refreshHistory();
          },
        ),
      ),
      Expanded(
        child: IndexedStack(
          index: _showHistory ? 1 : 0,
          children: [
            if (widget.store != null && _assets == null)
              Center(
                child: _loadingAssets
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: _loadAssets,
                        child: Text(_assetsMessage ?? 'Tải danh mục tài sản'),
                      ),
              )
            else
              IncidentReportForm(
                avatar: widget.avatar,
                name: widget.name,
                id: widget.id,
                role: widget.role,
                roomNames: widget.roomNames,
                equipmentNames: widget.equipmentNames,
                rooms: _assets?.rooms,
                equipment: _assets?.equipment,
                courseSections: _courseSections,
                nextReportId: () =>
                    widget.store == null ? widget.queue.nextId : 0,
                onSubmitted: _submit,
              ),
            _buildHistory(),
          ],
        ),
      ),
    ],
  );

  Widget _buildHistory() {
    final live = widget.store != null;
    return Column(
      children: [
        if (_loadingHistory) const LinearProgressIndicator(),
        if (_historyMessage case final message?)
          TextButton(onPressed: _refreshHistory, child: Text(message)),
        Expanded(
          child: IncidentReportHistory(
            reports: live
                ? _reports.values.map((entry) => entry.report).toList()
                : widget.queue.reportsFor(_owner),
            statusFor: (report) => live
                ? _reports[report.id]!.status
                : widget.queue.progressFor(_owner, report).status,
            onOpen: _showReport,
            onRefresh: live ? _refreshHistory : null,
          ),
        ),
      ],
    );
  }

  Future<void> _showReport(IncidentReport report) async {
    final store = widget.store;
    final saved = _reports[report.id];
    if (store != null && saved == null) return;
    final progress = saved == null
        ? widget.queue.progressFor(_owner, report)
        : (status: saved.status, updatedAt: saved.updatedAt);
    final evidence = saved?.hasPhoto == true
        ? store
              ?.loadPhoto(saved!.id)
              .then<Uint8List?>((photo) => photo, onError: (Object _) => null)
        : null;
    final shouldCancel = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => IncidentReportDetailsSheet(
        report: report,
        status: progress.status,
        updatedAt: progress.updatedAt,
        evidence: evidence,
      ),
    );
    if (!mounted || shouldCancel != true) return;
    if (store == null) {
      setState(() => widget.queue.cancel(_owner, report));
      return;
    }
    try {
      final cancelled = await store.cancel(saved!.id);
      if (mounted) setState(() => _remember(cancelled));
    } catch (_) {
      if (!mounted) return;
      await _refreshHistory();
      if (mounted) {
        setState(
          () => _historyMessage =
              'Không thể hủy báo cáo. Kiểm tra trạng thái rồi thử lại.',
        );
      }
    }
  }
}
