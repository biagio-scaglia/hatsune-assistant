import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';

/// La barra di input inferiore per digitare ed inviare messaggi.
/// Caratterizzata da estetica Glassmorphism e illuminazione attiva (glow) sul focus del testo.
class ChatInputBar extends StatefulWidget {
  final bool isThinking;
  final ValueChanged<String> onSendMessage;

  const ChatInputBar({
    super.key,
    required this.isThinking,
    required this.onSendMessage,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _submitMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isThinking) return;

    widget.onSendMessage(text);
    _controller.clear();
    // Rimette il focus per consentire l'invio continuo di messaggi da Desktop
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colore del bordo cambia dinamicamente se la barra ha il focus
    final currentBorderColor = _isFocused
        ? AppColors.primary
        : AppColors.border;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: GlassCard(
        borderColor: currentBorderColor,
        borderWidth: _isFocused ? 1.5 : 1.0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        child: Row(
          children: [
            // Campo di testo per l'input utente
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isThinking,
                decoration: InputDecoration(
                  hintText: widget.isThinking
                      ? 'Miku sta elaborando...'
                      : 'Scrivi un messaggio per Miku...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
                onSubmitted: (_) => _submitMessage(),
              ),
            ),
            
            // Tasto di invio messaggio con transizione visiva se Miku pensa
            AnimatedContainer(
              duration: AppDurations.fast,
              decoration: BoxDecoration(
                color: widget.isThinking
                    ? Colors.transparent
                    : AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: widget.isThinking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                onPressed: widget.isThinking ? null : _submitMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
