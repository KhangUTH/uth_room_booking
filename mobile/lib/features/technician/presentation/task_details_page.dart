import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/widgets/evidence_photos.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_sizes.dart';

import '../models/technician_task.dart';
import '../widgets/technician_panel.dart';
import '../widgets/technician_task_overview.dart';

class TaskDetailsPage extends StatefulWidget {
  final TechnicianTask task;
  final VoidCallback onChanged;

  const TaskDetailsPage({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  TechnicianTask get task => widget.task;

  late final _evidence = task.loadEvidence?.call();
  Timer? _timer;
  bool _refreshing = false;
  bool _available = true;

  @override
  void initState() {
    super.initState();
    if (task.loadStatus != null) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    if (_refreshing ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _refreshing = true;
    final previous = task.status;
    try {
      final available = await task.refreshStatus();
      if (mounted && (available != _available || task.status != previous)) {
        setState(() => _available = available);
      }
    } catch (_) {
      // Keep the current task while the connection is unavailable.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _advance() async {
    final accepting = task.status == TaskStatus.pending;
    try {
      if (!await task.advance() || !mounted) return;
    } on TechnicianTaskUnavailable {
      if (!mounted) return;
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Công việc đã thay đổi. Danh sách đang được cập nhật.'),
        ),
      );
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
      return;
    } catch (_) {
      if (mounted) {
        widget.onChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật công việc. Vui lòng thử lại.'),
          ),
        );
      }
      return;
    }
    widget.onChanged();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Đã cập nhật: ${task.status.label}')),
      );
    if (accepting) {
      Navigator.of(context).pop();
    } else {
      setState(() {});
    }
  }

  Widget _evidencePhotos() {
    final request = _evidence;
    if (request == null) return _photos(task.evidence);
    return FutureBuilder(
      future: request,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Không tải được ảnh minh chứng.');
        }
        return _photos(snapshot.requireData);
      },
    );
  }

  Widget _photos(List<Uint8List> photos) => photos.isEmpty
      ? const Text(
          'Không có ảnh minh chứng được đính kèm.',
          style: TextStyle(color: AppColors.textMuted),
        )
      : EvidencePhotos(photos: photos);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chi tiết công việc'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo/logo.jpg',
                height: 40,
                fit: BoxFit.contain,
                color: AppColors.background,
                colorBlendMode: BlendMode.multiply,
                semanticLabel: 'Logo Trường Đại học Giao thông Vận tải TP.HCM',
              ),
            ),
            const SizedBox(height: 12),
            TechnicianTaskOverview(task: task),
            if (!_available) const Text('Công việc không còn khả dụng.'),
            const SizedBox(height: 12),
            _TaskDetailsSection(
              icon: Icons.description_outlined,
              title: 'Mô tả sự cố',
              child: Text(task.description),
            ),
            const SizedBox(height: 12),
            _TaskDetailsSection(
              icon: Icons.photo_library_outlined,
              title: 'Hình ảnh minh chứng',
              child: _evidencePhotos(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !_available || task.status == TaskStatus.completed
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _advance,
                    child: Text(switch (task.status) {
                      TaskStatus.pending => 'Nhận việc',
                      _ => 'Hoàn tất công việc',
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TaskDetailsSection extends StatelessWidget {
  const _TaskDetailsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => TechnicianPanel(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTextSizes.section,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    ),
  );
}
