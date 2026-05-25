import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/state/assistant_state.dart';
import '../../../../shared/widgets/glass_card.dart';

class ChatScreen extends StatefulWidget {
  final AssistantState state;

  const ChatScreen({
    super.key,
    required this.state,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    widget.state.sendMessage(text);

    // Scorri verso il basso al termine dell'aggiunta del messaggio
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.medium,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.state.messages;
    final isThinking = widget.state.mikuState == MikuState.thinking;

    // Richiama l'auto-scorrimento all'arrivo dei messaggi
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      body: Column(
        children: [
          // Lista dei messaggi
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: messages.length + (isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                // Se l'assistente sta pensando, visualizza un indicatore nell'ultimo posto
                if (index == messages.length && isThinking) {
                  return const _ThinkingMessageBubble();
                }

                final message = messages[index];
                final isUser = message['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.md),
                        topRight: const Radius.circular(AppRadius.md),
                        bottomLeft: isUser ? const Radius.circular(AppRadius.md) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(AppRadius.md),
                      ),
                      border: Border.all(
                        color: isUser
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          message['text'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            message['time'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Barra di input
          _buildChatInputBar(isThinking),
        ],
      ),
    );
  }

  Widget _buildChatInputBar(bool isThinking) {
    return GlassCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          // Tasto allegati
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textSecondary),
            onPressed: isThinking ? null : () {},
          ),
          // Tasto input vocale
          IconButton(
            icon: const Icon(Icons.mic_none, color: AppColors.textSecondary),
            onPressed: isThinking ? null : () {},
          ),
          // Campo di testo per l'input utente
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isThinking,
              decoration: InputDecoration(
                hintText: isThinking 
                    ? 'Miku sta elaborando...' 
                    : 'Scrivi un messaggio per Miku...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          // Tasto di invio messaggio
          IconButton(
            icon: Icon(
              isThinking ? Icons.hourglass_empty : Icons.send_rounded, 
              color: isThinking ? AppColors.textMuted : AppColors.primary,
            ),
            onPressed: isThinking ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// Bolla di caricamento visualizzata mentre Miku elabora la risposta.
class _ThinkingMessageBubble extends StatelessWidget {
  const _ThinkingMessageBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.md),
            topRight: Radius.circular(AppRadius.md),
            bottomRight: Radius.circular(AppRadius.md),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Miku sta scrivendo...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
