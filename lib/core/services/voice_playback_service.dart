import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class VoicePlaybackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _onCompleteSubscription;
  VoidCallback? _onPlaybackComplete;

  VoicePlaybackService() {
    // Gestione dell'evento di riproduzione completata
    _onCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('[VoicePlaybackService] Riproduzione completata.');
      if (_onPlaybackComplete != null) {
        _onPlaybackComplete!();
      }
    });
  }

  /// Imposta il callback da invocare quando l'audio termina di essere riprodotto.
  void setOnPlaybackComplete(VoidCallback callback) {
    _onPlaybackComplete = callback;
  }

  /// Avvia la riproduzione di un file audio WAV da un URL remoto.
  Future<void> play(String url) async {
    try {
      debugPrint('[VoicePlaybackService] Riproduzione dell\'audio da URL: $url');
      // Ferma eventuali riproduzioni precedenti prima di avviare la nuova
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('[VoicePlaybackService] Errore durante la riproduzione audio: $e');
      rethrow;
    }
  }

  /// Interrompe immediatamente la riproduzione corrente.
  Future<void> stop() async {
    try {
      debugPrint('[VoicePlaybackService] Arresto forzato della riproduzione.');
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('[VoicePlaybackService] Errore arresto audio: $e');
    }
  }

  /// Libera le risorse dell'audio player.
  Future<void> dispose() async {
    await _onCompleteSubscription?.cancel();
    await _audioPlayer.dispose();
  }
}
