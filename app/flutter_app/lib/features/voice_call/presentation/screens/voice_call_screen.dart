


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/state/assistant_state.dart';
import '../../../../shared/widgets/miku_3d_viewer.dart';
import '../controllers/voice_call_controller.dart';
import '../widgets/waveform_indicator.dart';

class VoiceCallScreen extends StatefulWidget {
  final AssistantState state;

  const VoiceCallScreen({
    super.key,
    required this.state,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late VoiceCallController _controller;
  Timer? _timer;
  String _elapsedTimeString = "00:00";

  @override
  void initState() {
    super.initState();
    _controller = VoiceCallController(assistantState: widget.state);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startSession();
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.endSession();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.callStartTime != null) {
        final duration = DateTime.now().difference(_controller.callStartTime!);
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        setState(() {
          _elapsedTimeString = "$minutes:$seconds";
        });
      } else {
        setState(() {
          _elapsedTimeString = "00:00";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Flex(
              direction: Axis.vertical,
              children: [
                // Se siamo su Mobile, mostriamo l'avatar 3D all'interno della schermata
                if (isMobile) ...[
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Miku3DViewer(state: widget.state.mikuState),
                    ),
                  ),
                ],

                // Pannello delle informazioni di stato della chiamata
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusTitle(),
                              style: GoogleFonts.rajdhani(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _getStatusColor(),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStatusSubtitle(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppRadius.borderRadiusCircular,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _elapsedTimeString,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Area dei trascritti (Glassmorphism)
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      borderRadius: AppRadius.borderRadiusMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_controller.lastTranscript.isNotEmpty) ...[
                            _buildTranscriptBubble(
                              sender: 'Tu',
                              text: _controller.lastTranscript,
                              isUser: true,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (_controller.lastResponse.isNotEmpty) ...[
                            _buildTranscriptBubble(
                              sender: 'Miku',
                              text: _controller.lastResponse,
                              isUser: false,
                            ),
                          ],
                          if (_controller.lastTranscript.isEmpty && _controller.lastResponse.isEmpty) ...[
                            if (_controller.state == CallState.listening) ...[
                              _buildTranscriptBubble(
                                sender: 'Tu',
                                text: '🎙️ Sto ascoltando... parla ora.',
                                isUser: true,
                                isTemporary: true,
                              ),
                            ] else if (_controller.state == CallState.thinking) ...[
                              _buildTranscriptBubble(
                                sender: 'Tu',
                                text: '🎤 Audio registrato ed inviato al backend...',
                                isUser: true,
                                isTemporary: true,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildTranscriptBubble(
                                sender: 'Miku',
                                text: '⚡ Trascrizione ed elaborazione della risposta...',
                                isUser: false,
                                isTemporary: true,
                              ),
                            ] else if (_controller.state == CallState.error) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                                  child: Text(
                                    _controller.errorMessage ?? "C'è stato un problema di rete o di permessi.",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                                  child: Text(
                                    "Tocca 'Avvia Registrazione' e parla con Miku!",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Indicatori Waveform
                WaveformIndicator(
                  isAnimated: _controller.state == CallState.listening || _controller.state == CallState.talking,
                ),
                const SizedBox(height: AppSpacing.md),

                // Area Pulsanti di controllo chiamata
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildControlPanel(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranscriptBubble({
    required String sender,
    required String text,
    required bool isUser,
    bool isTemporary = false,
  }) {
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Text(
              sender,
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isUser ? AppColors.primary : AppColors.secondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primary.withValues(alpha: isTemporary ? 0.05 : 0.1)
                : AppColors.surfaceElevated.withValues(alpha: isTemporary ? 0.5 : 1.0),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(12),
            ),
            border: Border.all(
              color: isUser
                  ? AppColors.primary.withValues(alpha: isTemporary ? 0.1 : 0.2)
                  : AppColors.border.withValues(alpha: isTemporary ? 0.5 : 1.0),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isTemporary ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: 14,
              height: 1.3,
              fontStyle: isTemporary ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    final state = _controller.state;

    switch (state) {
      case CallState.idle:
        return _buildLargeButton(
          label: 'AVVIA REGISTRAZIONE',
          icon: Icons.mic,
          color: AppColors.primary,
          onTap: () => _controller.startRecording(),
        );

      case CallState.listening:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildLargeButton(
                label: 'FERMA E INVIA',
                icon: Icons.send,
                color: AppColors.success,
                onTap: () => _controller.stopRecordingAndSend(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: _buildLargeButton(
                label: 'ANNULLA',
                icon: Icons.close,
                color: AppColors.error,
                onTap: () => _controller.cancelRecording(),
              ),
            ),
          ],
        );

      case CallState.thinking:
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ELABORAZIONE IN CORSO...',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );

      case CallState.talking:
        return _buildLargeButton(
          label: 'INTERROMPI MIKU',
          icon: Icons.volume_off,
          color: AppColors.error,
          onTap: () => _controller.endSession(),
        );

      case CallState.error:
        return _buildLargeButton(
          label: 'RIPROVA',
          icon: Icons.refresh,
          color: AppColors.primary,
          onTap: () => _controller.startSession(),
        );
    }
  }

  Widget _buildLargeButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusTitle() {
    switch (_controller.state) {
      case CallState.idle:
        return "Miku è pronta";
      case CallState.listening:
        return "Ascolto in corso...";
      case CallState.thinking:
        return "Elaborazione...";
      case CallState.talking:
        return "Miku risponde...";
      case CallState.error:
        return "Errore connessione";
    }
  }

  String _getStatusSubtitle() {
    switch (_controller.state) {
      case CallState.idle:
        return "Tocca 'Avvia Registrazione' per parlare con Miku";
      case CallState.listening:
        return "Parla liberamente. Quando hai finito, tocca 'Ferma e Invia'";
      case CallState.thinking:
        return "Whisper e Ollama stanno lavorando...";
      case CallState.talking:
        return "Ascolta la risposta vocale";
      case CallState.error:
        return _controller.errorMessage ?? "Si è verificato un problema imprevisto.";
    }
  }

  Color _getStatusColor() {
    switch (_controller.state) {
      case CallState.idle:
        return AppColors.primary;
      case CallState.listening:
        return AppColors.error;
      case CallState.thinking:
        return AppColors.secondary;
      case CallState.talking:
        return AppColors.success;
      case CallState.error:
        return AppColors.error;
    }
  }
}
