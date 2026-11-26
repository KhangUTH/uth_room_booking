import 'package:flutter/material.dart';

import '../../booking/models/booking.dart';
import '../controllers/maintenance_proposal_controller.dart';
import '../models/maintenance_proposal.dart';
import 'maintenance_asset_field.dart';

Future<MaintenanceProposal?> showMaintenanceProposalDialog(
  BuildContext context,
  MaintenanceProposalController controller, {
  BookingAsset? asset,
  required bool rooms,
  List<BookingAsset>? assets,
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
      assets: assets,
    ),
  ),
);

class _MaintenanceForm extends StatefulWidget {
  const _MaintenanceForm({
    required this.controller,
    required this.rooms,
    this.initialAsset,
    this.assets,
  });

  final MaintenanceProposalController controller;
  final BookingAsset? initialAsset;
  final bool rooms;
  final List<BookingAsset>? assets;

  @override
  State<_MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<_MaintenanceForm> {
  final _form = GlobalKey<FormState>();
  final _reasonField = GlobalKey();
  final _reasonFocus = FocusNode();
  double _keyboardInset = 0;
  late BookingAsset? _asset = widget.initialAsset;
  String _reason = '';
  bool _sending = false;
  bool _sendFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset > _keyboardInset && _reasonFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fieldContext = _reasonField.currentContext;
        if (fieldContext != null && _reasonFocus.hasFocus) {
          Scrollable.ensureVisible(
            fieldContext,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
    _keyboardInset = keyboardInset;
  }

  @override
  void dispose() {
    _reasonFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !_form.currentState!.validate()) return;
    _form.currentState!.save();
    final proposal = MaintenanceProposal(asset: _asset!, reason: _reason);
    setState(() {
      _sending = true;
      _sendFailed = false;
    });
    try {
      await widget.controller.submit(proposal);
      if (mounted) Navigator.pop(context, proposal);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _sendFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: Padding(
        padding: EdgeInsets.only(bottom: _keyboardInset),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    'Đề xuất bảo trì',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  MaintenanceAssetField(
                    rooms: widget.rooms,
                    catalogAssets: widget.assets,
                    initialValue: _asset,
                    onChanged: (asset) => setState(() => _asset = asset),
                  ),
                  if (_asset case final asset?) Text(asset.detail),
                  TextFormField(
                    key: _reasonField,
                    focusNode: _reasonFocus,
                    enabled: !_sending,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Lý do bảo trì',
                      alignLabelWithHint: true,
                      hintText: 'Mô tả thiết bị hư hỏng và lý do cần thay mới',
                    ),
                    minLines: 2,
                    maxLines: 4,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nhập lý do bảo trì'
                        : null,
                    onSaved: (value) => _reason = value!.trim(),
                  ),
                  if (_sendFailed)
                    const Text('Chưa gửi được đề xuất. Vui lòng thử lại.'),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: Text(_sending ? 'Đang gửi…' : 'Gửi đề xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
