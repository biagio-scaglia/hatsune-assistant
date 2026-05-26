import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/ollama_service.dart';
import '../../features/models/domain/model_info.dart';

enum MikuState { idle, thinking, talking, victory }

/// Stato globale dell'applicazione. Gestisce la chat, i modelli, la posa 3D
/// di Miku ed il collegamento di rete a Ollama.
class AssistantState extends ChangeNotifier {
  final OllamaService _ollamaService = OllamaService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _playerCompleteSub;
  
  MikuState _mikuState = MikuState.idle;
  final List<Map<String, String>> _messages = [
    {
      'sender': 'assistant',
      'text': 'Ciao! Sono Hatsune Miku, la tua assistente virtuale di programmazione. Come posso aiutarti oggi? 🩵',
      'time': 'Adesso'
    }
  ];
  List<ModelInfo> _models = [];
  ModelInfo? _activeModel;
  bool _isConnected = false;
  bool _isLoadingModels = false;
  Timer? _victoryTimer;

  // Variabili delle impostazioni
  bool _voiceModeEnabled = false;
  double _temperature = 0.7;
  bool _neonGlowEnabled = true;
  bool _gpuOffloading = true;
  int _tokenContextLimit = 4096;
  String _cloudApiKey = "";
  String _colorTheme = "Cyan Cyberpunk";

  // I modelli cloud standard impostati dall'utente
  final List<ModelInfo> _cloudModels = const [
    ModelInfo(
      id: 'kimi-k2.6:cloud',
      name: 'kimi-k2.6:cloud',
      provider: 'Ollama Cloud',
      type: ModelType.cloud,
      status: ModelStatus.online,
      size: 'Cloud API',
      description: 'Modello Kimi versione K2.6 per compiti complessi in cloud.',
    ),
    ModelInfo(
      id: 'glm-5.1:cloud',
      name: 'glm-5.1:cloud',
      provider: 'Ollama Cloud',
      type: ModelType.cloud,
      status: ModelStatus.online,
      size: 'Cloud API',
      description: 'Modello GLM versione 5.1 ottimizzato per il ragionamento in lingua italiana.',
    ),
    ModelInfo(
      id: 'qwen3.5:cloud',
      name: 'qwen3.5:cloud',
      provider: 'Ollama Cloud',
      type: ModelType.cloud,
      status: ModelStatus.online,
      size: 'Cloud API',
      description: 'Modello Qwen 3.5 per coding avanzato e risposte rapide strutturate.',
    ),
    ModelInfo(
      id: 'nemotron-3-super:cloud',
      name: 'nemotron-3-super:cloud',
      provider: 'Ollama Cloud',
      type: ModelType.cloud,
      status: ModelStatus.online,
      size: 'Cloud API',
      description: 'Modello Nemotron 3 Super per risposte di alta qualità su architettura software.',
    ),
    ModelInfo(
      id: 'gemma4:31b-cloud',
      name: 'gemma4:31b-cloud',
      provider: 'Ollama Cloud',
      type: ModelType.cloud,
      status: ModelStatus.online,
      size: 'Cloud API',
      description: 'Modello Google Gemma 4 (31B) con straordinarie capacità logico-matematiche.',
    ),
  ];

  AssistantState() {
    // Registra il listener di completamento audio una sola volta
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (_mikuState == MikuState.talking) {
        setMikuState(MikuState.idle);
      }
    });
    refreshModels();
  }

  // Getters
  MikuState get mikuState => _mikuState;
  List<Map<String, String>> get messages => _messages;
  List<ModelInfo> get models => _models;
  ModelInfo? get activeModel => _activeModel;
  bool get isConnected => _isConnected;
  bool get isLoadingModels => _isLoadingModels;
  String get ollamaUrl => _ollamaService.baseUrl;
  bool get voiceModeEnabled => _voiceModeEnabled;
  double get temperature => _temperature;
  bool get neonGlowEnabled => _neonGlowEnabled;
  bool get gpuOffloading => _gpuOffloading;
  int get tokenContextLimit => _tokenContextLimit;
  String get cloudApiKey => _cloudApiKey;
  String get colorTheme => _colorTheme;

  /// Aggiorna l'URL dell'host Ollama e ricarica i modelli locali.
  void setOllamaUrl(String url) {
    _ollamaService.baseUrl = url;
    notifyListeners();
    refreshModels();
  }

  void setVoiceModeEnabled(bool value) {
    _voiceModeEnabled = value;
    notifyListeners();
  }

  void setTemperature(double value) {
    _temperature = value;
    notifyListeners();
  }

  void setNeonGlowEnabled(bool value) {
    _neonGlowEnabled = value;
    notifyListeners();
  }

  void setGpuOffloading(bool value) {
    _gpuOffloading = value;
    notifyListeners();
  }

  void setTokenContextLimit(int value) {
    _tokenContextLimit = value;
    notifyListeners();
  }

  void setCloudApiKey(String value) {
    _cloudApiKey = value;
    notifyListeners();
  }

  void setColorTheme(String value) {
    _colorTheme = value;
    notifyListeners();
  }

  /// Imposta il modello attivo per la chat.
  void selectModel(ModelInfo model) {
    _activeModel = model;
    notifyListeners();
  }

  /// Avvia una ricerca e ricarica i modelli locali e cloud.
  Future<void> refreshModels() async {
    _isLoadingModels = true;
    notifyListeners();

    try {
      final localList = await _ollamaService.fetchLocalModels();
      _isConnected = true;
      
      // Unisci modelli locali rilevati a quelli cloud predefiniti
      _models = [...localList, ..._cloudModels];

      // Se non c'è nessun modello attivo, imposta il primo locale o cloud disponibile
      if (_activeModel == null || !_models.any((m) => m.id == _activeModel!.id)) {
        _activeModel = localList.isNotEmpty ? localList.first : _cloudModels.first;
      }
    } catch (e) {
      _isConnected = false;
      // In caso di errore (Ollama non avviato), mostra solo i modelli Cloud finti per consentire test UI
      _models = [..._cloudModels];
      if (_activeModel == null || !_models.any((m) => m.id == _activeModel!.id)) {
        _activeModel = _cloudModels.first;
      }
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  /// Invia un messaggio all'assistente tramite Ollama.
  /// Se la modalità vocale è attiva, usa la pipeline unificata chat-with-tts
  /// per generare audio e riprodurlo automaticamente.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Cancella eventuali timer victory attivi e ferma audio in riproduzione
    _victoryTimer?.cancel();
    await _audioPlayer.stop();

    // Aggiunge messaggio utente
    _messages.add({
      'sender': 'user',
      'text': text,
      'time': _getCurrentTime(),
    });

    _mikuState = MikuState.thinking;
    notifyListeners();

    final modelName = _activeModel?.name ?? 'llama3';

    // Predispone i messaggi per l'endpoint di chat di Ollama
    final List<Map<String, String>> chatHistory = _messages.map((m) {
      return {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['text']!,
      };
    }).toList();

    try {
      String responseText;
      String? audioUrl;

      if (_voiceModeEnabled) {
        // Pipeline unificata: Chat + TTS in una singola richiesta
        final result = await _ollamaService.sendChatWithTTS(modelName, chatHistory);
        responseText = result['text'] as String;
        final ttsActive = result['tts_active'] as bool? ?? false;
        if (ttsActive && result['audio_url'] != null) {
          audioUrl = result['audio_url'] as String;
        }
      } else {
        // Solo chat testuale standard
        responseText = await _ollamaService.sendChatMessage(modelName, chatHistory);
      }

      _messages.add({
        'sender': 'assistant',
        'text': responseText,
        'time': _getCurrentTime(),
      });

      // Controlla se l'utente ha usato parole chiavi positive per attivare lo stato di vittoria (victory)
      final lowerText = text.toLowerCase();
      if (lowerText.contains('grazie') ||
          lowerText.contains('bella risposta') ||
          lowerText.contains('ottimo') ||
          lowerText.contains('brava') ||
          lowerText.contains('perfetto') ||
          lowerText.contains('grande')) {
        setMikuState(MikuState.victory);
        _victoryTimer = Timer(const Duration(seconds: 5), () {
          setMikuState(MikuState.idle);
        });
      } else {
        setMikuState(MikuState.talking);

        // Se c'è audio, riproducilo e torna a idle al termine della riproduzione
        if (audioUrl != null) {
          await _playAudio(audioUrl);
        } else {
          // Senza audio, torna a idle dopo un tempo stimato
          _victoryTimer = Timer(const Duration(seconds: 6), () {
            setMikuState(MikuState.idle);
          });
        }
      }
    } catch (e) {
      _messages.add({
        'sender': 'assistant',
        'text': '⚠️ Errore di connessione a Ollama: Assicurati che Ollama sia avviato localmente su $ollamaUrl e che il modello $_activeModel sia installato.\n\nDettagli errore: $e',
        'time': _getCurrentTime(),
      });
      setMikuState(MikuState.idle);
    }
  }

  /// Riproduce un file audio WAV dall'URL generato dal backend TTS.
  /// Miku resta nello stato "talking" fino al termine della riproduzione.
  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('[Audio] Errore riproduzione audio: $e');
      // Se la riproduzione fallisce, torna a idle dopo un breve ritardo
      _victoryTimer = Timer(const Duration(seconds: 4), () {
        setMikuState(MikuState.idle);
      });
    }
  }

  /// Forza lo stato di Miku e aggiorna i listener.
  void setMikuState(MikuState state) {
    _mikuState = state;
    notifyListeners();
  }

  /// Forza manualmente lo stato di vittoria (ad esempio cliccando sulle card o tramite azioni rapide).
  void triggerVictoryManual() {
    _victoryTimer?.cancel();
    setMikuState(MikuState.victory);
    _victoryTimer = Timer(const Duration(seconds: 5), () {
      setMikuState(MikuState.idle);
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _victoryTimer?.cancel();
    _playerCompleteSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
