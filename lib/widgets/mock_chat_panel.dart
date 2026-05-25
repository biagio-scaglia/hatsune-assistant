import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pannello chat mockup con messaggi placeholder realistici e input bar finta.
class MockChatPanel extends StatelessWidget {
  const MockChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MikuColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: MikuColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        children: [
          // Header chat
          _ChatHeader(),

          // Lista messaggi
          Expanded(child: _MessageList()),

          // Input bar finta
          _FakeInputBar(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header del pannello chat
// ---------------------------------------------------------------------------

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: const BoxDecoration(
        color: MikuColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: MikuColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar piccolo Miku
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [MikuColors.cyan, MikuColors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color.fromRGBO(57, 197, 187, 0.5),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'ミ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MikuColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Chat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: MikuColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Indicatore "online"
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: MikuColors.cyan,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Text(
            'Online',
            style: TextStyle(
              fontSize: 11,
              color: MikuColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista messaggi mockup
// ---------------------------------------------------------------------------

/// Dati di un singolo messaggio mockup
class _MockMessage {
  const _MockMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  final String text;
  final bool isUser;
  final String time;
}

/// Messaggi placeholder
const _messages = [
  _MockMessage(
    text: 'Sto analizzando il tuo codice...',
    isUser: false,
    time: '14:32',
  ),
  _MockMessage(
    text: 'Puoi ottimizzare il ciclo nella funzione processData?',
    isUser: true,
    time: '14:33',
  ),
  _MockMessage(
    text: 'Ho trovato una possibile ottimizzazione. '
        'Posso ridurre la complessità da O(n²) a O(n log n).',
    isUser: false,
    time: '14:33',
  ),
  _MockMessage(
    text: 'Vuoi che riscriva questa funzione in modo più pulito?',
    isUser: false,
    time: '14:34',
  ),
];

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: _messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _ChatBubble(message: msg);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Singola bubble messaggio
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _MockMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Avatar
            _BubbleAvatar(isUser: isUser),
            const SizedBox(width: AppSpacing.sm),

            // Contenuto
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? MikuColors.userBubble
                      : MikuColors.assistantBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.md),
                    topRight: const Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(isUser ? AppRadius.md : 2),
                    bottomRight: Radius.circular(isUser ? 2 : AppRadius.md),
                  ),
                  border: Border.all(
                    color: isUser
                        ? const Color.fromRGBO(30, 58, 95, 0.8)
                        : const Color.fromRGBO(57, 197, 187, 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: MikuColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: MikuColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar piccolo nelle bubble
// ---------------------------------------------------------------------------

class _BubbleAvatar extends StatelessWidget {
  const _BubbleAvatar({required this.isUser});

  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? MikuColors.userBubble : MikuColors.surfaceElevated,
        border: Border.all(
          color: isUser ? MikuColors.border : MikuColors.cyan,
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person_outline : Icons.auto_awesome,
          size: 13,
          color: isUser ? MikuColors.textSecondary : MikuColors.cyan,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar finta (solo estetica)
// ---------------------------------------------------------------------------

class _FakeInputBar extends StatelessWidget {
  const _FakeInputBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: const BoxDecoration(
        color: MikuColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: MikuColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Campo di testo finto
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: MikuColors.background,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: MikuColors.border,
                  width: 1,
                ),
              ),
              child: const Text(
                'Scrivi un messaggio...',
                style: TextStyle(
                  fontSize: 13,
                  color: MikuColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Pulsante invio decorativo
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [MikuColors.cyan, MikuColors.cyanLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              size: 18,
              color: MikuColors.background,
            ),
          ),
        ],
      ),
    );
  }
}
