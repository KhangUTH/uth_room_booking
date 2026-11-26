import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../incident_report/widgets/incident_photo_picker.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_history_sheet.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_incident_draft_dialog.dart';
import '../widgets/chat_turn.dart';
import '../widgets/chat_welcome.dart';

enum ChatDestination { schedule, reports }

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.name,
    required this.controller,
    required this.isTechnician,
  });

  final String name;
  final ChatController controller;
  final bool isTechnician;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Uint8List? _image;
  ChatController get _chat => widget.controller;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text, {bool attachImage = false, ChatRoom? room}) {
    final photo = attachImage ? _image : null;
    if (text.trim().isEmpty && photo == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _chat.send(text, image: photo, room: room);
    if (attachImage) {
      _input.clear();
      setState(() => _image = null);
    }
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await pickIncidentPhoto(context);
      if (mounted && photo != null) setState(() => _image = photo);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được ảnh. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Xóa hội thoại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) _chat.clear();
  }

  Future<void> _openHistory() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => ChatHistorySheet(
        titles: _chat.historyTitles,
        currentTitle: _chat.currentTitle,
      ),
    );
    if (!mounted || index == null) return;
    _chat.openConversation(index);
    _resetDraft();
  }

  void _startNewConversation() {
    _chat.startNewConversation();
    _resetDraft();
  }

  void _resetDraft() {
    FocusManager.instance.primaryFocus?.unfocus();
    _input.clear();
    setState(() => _image = null);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _editIncident(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ChatIncidentDraftDialog(message: message),
    );
    if (mounted && confirmed == true) _chat.confirm(message);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _chat,
    builder: (context, _) {
      final messages = _chat.messages;
      return Scaffold(
        backgroundColor: AppColors.chatBackground,
        body: ColoredBox(
          color: AppColors.chatBackground,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Column(
                  children: [
                    ChatHeader(
                      isLoading: _chat.isLoading,
                      canClear: messages.isNotEmpty,
                      onNewConversation: _startNewConversation,
                      onOpenHistory: _openHistory,
                      onClear: _clear,
                    ),
                    Expanded(
                      child: messages.isEmpty
                          ? ChatWelcome(
                              name: widget.name,
                              onSend: _send,
                              isTechnician: widget.isTechnician,
                            )
                          : ListView.builder(
                              reverse: true,
                              controller: _scroll,
                              padding: const EdgeInsets.all(12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    messages[messages.length - 1 - index];
                                return ChatTurn(
                                  key: ObjectKey(message),
                                  message: message,
                                  latest: index == 0,
                                  isTechnician: widget.isTechnician,
                                  controller: _chat,
                                  onSend: _send,
                                  onOpenSchedule: () => Navigator.pop(
                                    context,
                                    ChatDestination.schedule,
                                  ),
                                  onOpenReports: () => Navigator.pop(
                                    context,
                                    ChatDestination.reports,
                                  ),
                                  onEditIncident: _editIncident,
                                );
                              },
                            ),
                    ),
                    ChatInputBar(
                      key: ObjectKey(_chat.conversationKey),
                      input: _input,
                      image: _image,
                      onPickPhoto: _pickPhoto,
                      onRemovePhoto: () => setState(() => _image = null),
                      onSend: (text) => _send(text, attachImage: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
