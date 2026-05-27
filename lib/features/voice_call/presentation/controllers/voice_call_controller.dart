import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/state/assistant_state.dart';
import '../../../../core/services/voice_recorder_service.dart';
import '../../../../core/services/voice_playback_service.dart';

enum CallState { idle, listening, thinking, talking, error }

class VoiceCallController extends ChangeNotifier {
  final AssistantState assistantState;
  final VoiceRecorderService _recorderService = VoiceRecorderService();
  final VoicePlaybackService _playbackService = VoicePlaybackService();

  CallState _state = CallState.idle;
  String? _conversationId;
  String _lastTranscript = "";
  String _lastResponse = "";
  String? _errorMessage;
  DateTime? _callStartTime;


  CallState get state => _state;
  String get lastTranscript => _lastTranscript;
  String get lastResponse => _lastResponse;
  String? get errorMessage => _errorMessage;
  DateTime? get callStartTime => _callStartTime;
  String? get conversationId => _conversationId;

  VoiceCallController({required this.assistantState}) {
    // Al termine della riproduzione vocale di Miku, torna in stato Idle
    _playbackService.setOnPlaybackComplete(() {
      if (_state == CallState.talking) {
        _setState(CallState.idle);
        assistantState.setMikuState(MikuState.idle);
      }
    });
  }

  void startSession() {
    _callStartTime = DateTime.now();
    _conversationId = null;
    _lastTranscript = "";
    _lastResponse = "";
    _errorMessage = null;
    _setState(CallState.idle);
    assistantState.setMikuState(MikuState.idle);
  }

  void endSession() {
    _playbackService.stop();
    _recorderService.stopRecording();
    _callStartTime = null;
    _setState(CallState.idle);
    assistantState.setMikuState(MikuState.idle);
  }

  /// Avvia la registrazione dal microfono dell'utente
  Future<void> startRecording() async {
    if (_state != CallState.idle && _state != CallState.error) return;

    try {
      _errorMessage = null;
      await _playbackService.stop(); // Interrompi audio precedente se attivo
      
      await _recorderService.startRecording();
      _setState(CallState.listening);
      assistantState.setMikuState(MikuState.listening);
    } catch (e) {
      debugPrint('[VoiceCallController] Errore avvio registrazione: $e');
      _errorMessage = 'Impossibile attivare il microfono: ${e.toString()}';
      _setState(CallState.error);
      assistantState.setMikuState(MikuState.idle);
    }
  }

  /// Ferma la registrazione e invia l'audio al backend per l'elaborazione del turno
  Future<void> stopRecordingAndSend() async {
    if (_state != CallState.listening) return;

    try {
      _setState(CallState.thinking);
      assistantState.setMikuState(MikuState.thinking);

      final path = await _recorderService.stopRecording();
      if (path == null) {
        throw Exception('Audio non registrato o nullo');
      }

      await _uploadAndProcessAudio(path);
    } catch (e) {
      debugPrint('[VoiceCallController] Errore arresto e invio registrazione: $e');
      _errorMessage = 'Errore di elaborazione vocale: ${e.toString()}';
      _setState(CallState.error);
      assistantState.setMikuState(MikuState.idle);
    }
  }

  /// Gestisce la richiesta multipart verso il backend
  Future<void> _uploadAndProcessAudio(String filePath) async {
    try {
      final url = Uri.parse('${assistantState.ollamaUrl}/voice/turn');
      final request = http.MultipartRequest('POST', url);

      // Aggiungi file audio
      List<int> bytes;
      String filename = 'audio.wav';

      if (kIsWeb) {
        // Legge i byte dal Blob URL della registrazione in memoria nel browser
        final response = await http.get(Uri.parse(filePath));
        bytes = response.bodyBytes;
      } else {
        bytes = await File(filePath).readAsBytes();
        filename = filePath.replaceAll('\\', '/').split('/').last;
      }

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));

      // Aggiungi parametri form-data opzionali
      if (_conversationId != null) {
        request.fields['conversation_id'] = _conversationId!;
      }
      
      final activeModel = assistantState.activeModel?.name ?? 'llama3:latest';
      request.fields['model'] = activeModel;
      
      // Impostazioni globali da AssistantState
      // Utilizziamo it_IT-paola-medium come default per la voce femminile di Miku
      request.fields['voice'] = 'it_IT-paola-medium';
      request.fields['speed'] = '1.0';
      request.fields['temperature'] = assistantState.temperature.toString();

      debugPrint('[VoiceCallController] Invio richiesta vocale a $url con modello $activeModel...');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        _lastTranscript = data['transcript'] as String? ?? "";
        _lastResponse = data['assistant_text'] as String? ?? "";
        _conversationId = data['conversation_id'] as String?;
        final audioUrl = data['audio_url'] as String?;

        debugPrint('[VoiceCallController] Risposta backend ricevuta. Transcript: "$_lastTranscript"');

        if (_lastTranscript.trim().isEmpty) {
          // Nessun audio o testo decifrato, torna in Idle
          _setState(CallState.idle);
          assistantState.setMikuState(MikuState.idle);
          return;
        }

        // Allinea la cronologia messaggi di testo principale
        assistantState.addMessageManually('user', _lastTranscript);
        assistantState.addMessageManually('assistant', _lastResponse);

        if (audioUrl != null && audioUrl.isNotEmpty) {
          _setState(CallState.talking);
          assistantState.setMikuState(MikuState.talking);
          await _playbackService.play(audioUrl);
        } else {
          // Se non è disponibile l'audio, mostriamo solo il testo e torniamo a idle
          _setState(CallState.idle);
          assistantState.setMikuState(MikuState.idle);
        }
      } else {
        throw Exception('Errore risposta server (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[VoiceCallController] Errore chiamata /voice/turn: $e');
      _errorMessage = 'Connessione al backend fallita: ${e.toString()}';
      _setState(CallState.error);
      assistantState.setMikuState(MikuState.idle);
    } finally {
      if (!kIsWeb) {
        // Cancella il file locale registrato per non occupare spazio disco inutilmente
        final file = File(filePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            debugPrint('[VoiceCallController] Impossibile eliminare il file temporaneo locale: $e');
          }
        }
      }
    }
  }

  void _setState(CallState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorderService.dispose();
    _playbackService.dispose();
    super.dispose();
  }
}
