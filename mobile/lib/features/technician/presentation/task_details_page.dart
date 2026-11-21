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

  Future<void> _release() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trả lại công việc?'),
        content: const Text(
          'Công việc sẽ xuất hiện lại để kỹ thuật viên khác có thể nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Trả lại'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      if (!await task.release() || !mounted) return;
      widget.onChanged();
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không trả lại được công việc. Vui lòng tải lại và thử lại.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _advance() async {
    final accepting = task.status == TaskStatus.pending;
    try {
      if (!await task.advanceSaved() || !mounted) return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không cập nhật được công việc. Vui lòng tải lại và thử lại.',
            ),
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: task,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
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
              child: _evidence != null
                  ? FutureBuilder(
                      future: _evidence,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'Không tải được ảnh. Mở lại chi tiết để thử lại.',
                          );
                        }
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        return EvidencePhotos(photos: snapshot.requireData);
                      },
                    )
                  : task.evidence.isEmpty
                  ? const Text(
                      'Không có ảnh minh chứng được đính kèm.',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  : EvidencePhotos(photos: task.evidence),
            ),
          ],
        ),
      ),
      bottomNavigationBar: task.status == TaskStatus.completed
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.status == TaskStatus.inProgress &&
                        task.returnToQueue != null)
                      TextButton(
                        onPressed: task.saving ? null : _release,
                        child: const Text('Trả lại công việc'),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: task.saving ? null : _advance,
                        child: Text(
                          task.saving
                              ? 'Đang lưu…'
                              : switch (task.status) {
                                  TaskStatus.pending => 'Nhận việc',
                                  _ => 'Hoàn tất công việc',
                                },
                        ),
                      ),
                    ),
                  ],
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
