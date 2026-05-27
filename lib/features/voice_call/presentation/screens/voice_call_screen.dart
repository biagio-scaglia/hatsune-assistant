


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
  bool _isTapToTalkMode = true; // Modalità predefinita: Tap-to-Talk
  Timer? _timer;
  String _elapsedTimeString = "00:00";

  @override
  void initState() {
    super.initState();
    _controller = VoiceCallController(assistantState: widget.state);
    _controller.startSession();
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
                      Column(
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
                          if (_controller.lastTranscript.isEmpty && _controller.lastResponse.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xl),
                                child: Text(
                                  _controller.state == CallState.error
                                      ? "C'è stato un problema di rete o di permessi."
                                      : "Avvia il microfono e parla con Miku!",
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

                // Selettore della modalità di interazione (PTT vs Tap-to-Talk)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Tocca per Parlare'),
                      selected: _isTapToTalkMode,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: _isTapToTalkMode ? AppColors.primary : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: _isTapToTalkMode ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected && _controller.state == CallState.idle) {
                          setState(() => _isTapToTalkMode = true);
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ChoiceChip(
                      label: const Text('Tieni Premuto (PTT)'),
                      selected: !_isTapToTalkMode,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: !_isTapToTalkMode ? AppColors.primary : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: !_isTapToTalkMode ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected && _controller.state == CallState.idle) {
                          setState(() => _isTapToTalkMode = false);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Area Pulsante Principale di chiamata
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildMicButton(),
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
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(12),
            ),
            border: Border.all(
              color: isUser
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.border,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    final state = _controller.state;

    // Gestione gesti differenziata in base alla modalità
    if (_isTapToTalkMode) {
      return GestureDetector(
        onTap: () {
          if (state == CallState.idle || state == CallState.error) {
            _controller.startRecording();
          } else if (state == CallState.listening) {
            _controller.stopRecordingAndSend();
          }
        },
        child: _buildButtonBody(),
      );
    } else {
      // Modalità Push-to-Talk (PTT)
      return GestureDetector(
        onLongPressStart: (_) {
          if (state == CallState.idle || state == CallState.error) {
            _controller.startRecording();
          }
        },
        onLongPressEnd: (_) {
          if (state == CallState.listening) {
            _controller.stopRecordingAndSend();
          }
        },
        child: _buildButtonBody(),
      );
    }
  }

  Widget _buildButtonBody() {
    final state = _controller.state;
    final isListening = state == CallState.listening;
    final isThinking = state == CallState.thinking;

    Color buttonColor = AppColors.primary;
    IconData icon = Icons.mic;
    
    if (isListening) {
      buttonColor = AppColors.error;
      icon = Icons.mic_off;
    } else if (isThinking) {
      buttonColor = AppColors.secondary;
      icon = Icons.hourglass_empty;
    } else if (state == CallState.error) {
      buttonColor = AppColors.error;
      icon = Icons.refresh;
    }

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: buttonColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: buttonColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: isThinking
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              )
            : Icon(
                icon,
                color: buttonColor,
                size: 32,
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
        return _isTapToTalkMode
            ? "Tocca il microfono per parlare"
            : "Tieni premuto il microfono per parlare";
      case CallState.listening:
        return _isTapToTalkMode
            ? "Tocca di nuovo per inviare"
            : "Rilascia per inviare l'audio";
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
