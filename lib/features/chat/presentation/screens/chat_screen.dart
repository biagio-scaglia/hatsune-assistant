import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Messaggi mock per popolare la chat iniziale
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'assistant',
      'text': 'Ciao! Sono Hatsune Miku, la tua assistente virtuale di programmazione. Come posso aiutarti oggi? 🩵',
      'time': '10:00 AM'
    },
    {
      'sender': 'user',
      'text': 'Ciao Miku, potresti scrivermi un semplice script Python per fare scraping di un sito web?',
      'time': '10:01 AM'
    },
    {
      'sender': 'assistant',
      'text': 'Certamente! Ecco un esempio basico usando `requests` e `BeautifulSoup`:\n\n```python\nimport requests\nfrom bs4 import BeautifulSoup\n\nurl = "https://example.com"\nresponse = requests.get(url)\nsoup = BeautifulSoup(response.text, "html.parser")\nprint(soup.title.text)\n```\n\nRicorda di installare le dipendenze prima di avviarlo!',
      'time': '10:02 AM'
    },
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': '10:05 AM',
      });
      _messageController.clear();
    });

    // Auto-scroll verso il basso dopo l'invio del messaggio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.medium,
        curve: Curves.easeOut,
      );
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
    return Scaffold(
      body: Column(
        children: [
          // Lista dei messaggi
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
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
                        Text(
                          message['text'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            message['time'],
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

          // Barra di input con gestione corretta della tastiera
          _buildChatInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatInputBar() {
    return GlassCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          // Tasto allegati
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          // Tasto input vocale
          IconButton(
            icon: const Icon(Icons.mic_none, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          // Campo di testo per l'input utente
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Scrivi un messaggio per Miku...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          // Tasto di invio messaggio
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
