import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/state/assistant_state.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';

/// La Schermata Chat principale.
/// Gestisce la sincronizzazione dello stato globale della chat, lo scrolling automatico
/// e l'integrazione dei widget della chat in modo responsive.
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
  final ScrollController _scrollController = ScrollController();
  int _lastMessagesLength = 0;

  @override
  void initState() {
    super.initState();
    _lastMessagesLength = widget.state.messages.length;
    // Registra il listener per reagire immediatamente ai cambi di stato
    widget.state.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChanged);
      widget.state.addListener(_onStateChanged);
      _lastMessagesLength = widget.state.messages.length;
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  /// Callback scatenata ogni volta che lo stato notifica un cambiamento.
  /// Gestisce il rebuild immediato e controlla se avviare lo scorrimento verso il basso.
  void _onStateChanged() {
    if (!mounted) return;

    setState(() {
      final currentLength = widget.state.messages.length;
      // Scorri verso il basso solo se la lista dei messaggi è cresciuta
      // o se l'assistente è entrato in stato "thinking"
      if (currentLength > _lastMessagesLength) {
        _lastMessagesLength = currentLength;
        _scrollToBottom();
      } else if (widget.state.mikuState == MikuState.thinking) {
        _scrollToBottom();
      }
    });
  }

  /// Invia un messaggio all'assistente.
  void _sendMessage(String text) {
    widget.state.sendMessage(text);
    // Forza lo scroll immediato al click di invio per reattività visiva
    _scrollToBottom();
  }

  /// Effettua lo scorrimento verso il basso dopo la fase di layout di Flutter.
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
  Widget build(BuildContext context) {
    final messages = widget.state.messages;
    final isThinking = widget.state.mikuState == MikuState.thinking;

    // Se l'utente non ha ancora inviato messaggi, mostra lo stato vuoto con suggerimenti
    final isChatEmpty = messages.length <= 1;

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Feed messaggi o Stato vuoto con suggerimenti
          Expanded(
            child: isChatEmpty
                ? ChatEmptyState(onSuggestionSelected: _sendMessage)
                : ChatMessageList(
                    messages: messages,
                    isThinking: isThinking,
                    scrollController: _scrollController,
                  ),
          ),

          // Barra di inserimento testo
          ChatInputBar(
            isThinking: isThinking,
            onSendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
