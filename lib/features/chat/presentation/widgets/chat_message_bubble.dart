import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';

/// Rappresenta una singola bolla di messaggio nella chat.
/// Dispone il testo e l'avatar a sinistra (Miku) o a destra (Utente) con estetica cyberpunk.
class ChatMessageBubble extends StatelessWidget {
  final Map<String, String> message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message['sender'] == 'user';
    final text = message['text'] ?? '';
    final time = message['time'] ?? '';

    // Breakpoint larghezza massima bolla
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth > 800 ? 550.0 : screenWidth * 0.75;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Se assistente, mostra l'avatar a sinistra
          if (!isUser) ...[
            _buildMikuAvatar(context),
            const SizedBox(width: AppSpacing.sm),
          ],

          // Bolla di testo vera e propria
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Messaggio copiato negli appunti!'),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxBubbleWidth,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.md),
                    topRight: const Radius.circular(AppRadius.md),
                    bottomLeft: isUser ? const Radius.circular(AppRadius.md) : Radius.zero,
                    bottomRight: isUser ? Radius.zero : const Radius.circular(AppRadius.md),
                  ),
                  border: Border.all(
                    color: isUser
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColors.border,
                    width: 1.0,
                  ),
                  boxShadow: [
                    if (isUser)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.md),
                    topRight: const Radius.circular(AppRadius.md),
                    bottomLeft: isUser ? const Radius.circular(AppRadius.md) : Radius.zero,
                    bottomRight: isUser ? Radius.zero : const Radius.circular(AppRadius.md),
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Riga d'accento decorativa cyberpunk a sinistra per Miku
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser)
                              Container(
                                width: 3.5,
                                height: 38,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: SelectableText(
                                  text,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    height: 1.45,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Timestamp e feedback copia
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                time,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Se utente, mostra l'avatar a destra
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            _buildUserAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMikuAvatar(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.cyberGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '39',
          style: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.background,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
