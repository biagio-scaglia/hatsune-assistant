import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Verifica e richiede i permessi del microfono se necessario.
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('[VoiceRecorderService] Errore verifica permessi: $e');
      return false;
    }
  }

  /// Avvia la registrazione audio salvandola in un file temporaneo in formato WAV.
  /// Ritorna il percorso assoluto del file generato.
  Future<String> startRecording() async {
    if (_isRecording) {
      throw Exception('Registrazione già attiva');
    }

    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception('Permesso microfono non concesso');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_input_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = p.join(tempDir.path, fileName);

      debugPrint('[VoiceRecorderService] Avvio registrazione su: $filePath');
      
      const config = RecordConfig(
        encoder: AudioEncoder.wav, // WAV lineare PCM
        sampleRate: 16000,         // 16kHz ottimizzato per Whisper
        numChannels: 1,            // Mono
        autoGain: true,            // Regolazione automatica volume
        echoCancel: true,          // Rimozione eco
        noiseSuppress: true,       // Soppressione rumore di fondo
      );

      await _recorder.start(config, path: filePath);
      _isRecording = true;
      return filePath;
    } catch (e) {
      debugPrint('[VoiceRecorderService] Errore avvio registrazione: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Interrompe la registrazione e restituisce il percorso del file audio salvato.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      debugPrint('[VoiceRecorderService] Arresto registrazione...');
      final path = await _recorder.stop();
      _isRecording = false;
      debugPrint('[VoiceRecorderService] Registrazione salvata in: $path');
      return path;
    } catch (e) {
      debugPrint('[VoiceRecorderService] Errore arresto registrazione: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Pulisce le risorse.
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (e) {
      debugPrint('[VoiceRecorderService] Errore dispose recorder: $e');
    }
  }
}
