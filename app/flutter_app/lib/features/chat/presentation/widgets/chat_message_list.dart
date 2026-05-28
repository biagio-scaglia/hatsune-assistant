import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import 'chat_message_bubble.dart';
import 'typing_indicator.dart';

/// La lista scrollabile dei messaggi di chat.
/// Contiene un vincolo di larghezza massima (800px) per rimanere leggibile ed elegante su desktop/tablet.
class ChatMessageList extends StatelessWidget {
  final List<Map<String, String>> messages;
  final bool isThinking;
  final ScrollController scrollController;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.isThinking,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          itemCount: messages.length + (isThinking ? 1 : 0),
          itemBuilder: (context, index) {
            // Se l'assistente sta pensando, l'ultimo elemento è l'indicatore animato
            if (index == messages.length && isThinking) {
              return const TypingIndicator();
            }

            final message = messages[index];
            return ChatMessageBubble(message: message);
          },
        ),
      ),
    );
  }
}
