import 'package:flutter/material.dart';

import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';
import '../controllers/maintenance_proposal_controller.dart';
import '../models/maintenance_proposal.dart';
import 'maintenance_asset_field.dart';
import 'maintenance_schedule_field.dart';

Future<MaintenanceProposal?> showMaintenanceProposalDialog(
  BuildContext context,
  MaintenanceProposalController controller, {
  BookingAsset? asset,
  required bool rooms,
}) => showModalBottomSheet<MaintenanceProposal>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: BoxConstraints(
    maxWidth: 640,
    maxHeight: MediaQuery.sizeOf(context).height * .92,
  ),
  builder: (_) => SizedBox(
    width: double.infinity,
    child: _MaintenanceForm(
      controller: controller,
      initialAsset: asset,
      rooms: rooms,
    ),
  ),
);

class _MaintenanceForm extends StatefulWidget {
  const _MaintenanceForm({
    required this.controller,
    required this.rooms,
    this.initialAsset,
  });

  final MaintenanceProposalController controller;
  final BookingAsset? initialAsset;
  final bool rooms;

  @override
  State<_MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<_MaintenanceForm> {
  final _form = GlobalKey<FormState>();
  late BookingAsset? _asset = widget.initialAsset;
  final _today = DateUtils.dateOnly(DateTime.now());
  DateTime? _date;
  int? _slotIndex;
  String _reason = '';

  BookingSlot? get _schedule {
    final asset = _asset;
    final date = _date;
    final index = _slotIndex;
    if (asset == null || date == null || index == null) return null;
    return (date: date, asset: asset.name, index: index);
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    Navigator.pop(
      context,
      MaintenanceProposal(asset: _asset!, reason: _reason, schedule: _schedule),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo/logo.jpg',
                  height: 40,
                  fit: BoxFit.contain,
                  semanticLabel: 'Logo UTH',
                ),
              ),
              Text(
                'Tạo đề xuất bảo trì',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              MaintenanceAssetField(
                rooms: widget.rooms,
                initialValue: _asset,
                onChanged: (asset) => setState(() => _asset = asset),
              ),
              if (_asset case final asset?) Text(asset.detail),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Lý do bảo trì',
                  alignLabelWithHint: true,
                  hintText: 'Mô tả việc cần kiểm tra hoặc bảo trì',
                ),
                minLines: 2,
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập lý do bảo trì'
                    : null,
                onSaved: (value) => _reason = value!.trim(),
              ),
              MaintenanceScheduleField(
                today: _today,
                date: _date,
                slotIndex: _slotIndex,
                onDateChanged: (date) => setState(() => _date = date),
                onSlotChanged: (index) => setState(() => _slotIndex = index),
                onClear: () => setState(() {
                  _date = null;
                  _slotIndex = null;
                }),
              ),
              if (schedule != null &&
                  widget.controller.conflictsWithBooking(schedule))
                Text(
                  'Trùng ca ${bookingStartTimes[schedule.index]} – ${bookingEndTimes[schedule.index]} đã được duyệt.',
                  style: const TextStyle(color: Color(0xFF815200)),
                ),
              FilledButton(
                onPressed: _submit,
                child: const Text('Gửi đề xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
