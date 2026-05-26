import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/models/domain/model_info.dart';

/// Servizio di interfaccia con il nostro backend AI in FastAPI.
/// Gestisce il recupero dei modelli e l'invio dei messaggi di chat tramite bridge.
class OllamaService {
  String baseUrl;

  // L'URL predefinito punta al backend FastAPI (porta 8000) anziché a Ollama direttamente
  OllamaService({this.baseUrl = 'http://localhost:8000/api/v1'});

  /// Recupera la lista dei modelli locali caricati in Ollama attraverso il backend.
  Future<List<ModelInfo>> fetchLocalModels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/models')).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> modelsJson = data['models'] ?? [];

        return modelsJson.map((m) {
          return ModelInfo(
            id: m['id'] as String,
            name: m['name'] as String,
            provider: m['provider'] as String? ?? 'Ollama (Locale)',
            type: ModelType.local,
            status: ModelStatus.downloaded,
            size: m['size'] as String,
            description: m['description'] as String? ?? '',
          );
        }).toList();
      } else {
        throw Exception('Risposta non valida dal backend: ${response.statusCode}');
      }
    } catch (e) {
      // Propaga l'eccezione di rete o timeout
      rethrow;
    }
  }

  /// Invia la cronologia dei messaggi al backend e restituisce la risposta dell'assistente.
  Future<String> sendChatMessage(String model, List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['message']['content'] as String;
      } else {
        throw Exception('Errore risposta backend (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Invia i messaggi al backend con pipeline unificata Chat + TTS.
  /// Ritorna una mappa con 'text', 'audio_url' e 'tts_active'.
  Future<Map<String, dynamic>> sendChatWithTTS(
    String model,
    List<Map<String, String>> messages, {
    String? voice,
    double? speed,
  }) async {
    try {
      final body = <String, dynamic>{
        'model': model,
        'messages': messages,
      };
      if (voice != null) body['voice'] = voice;
      if (speed != null) body['speed'] = speed;

      final response = await http.post(
        Uri.parse('$baseUrl/chat-with-tts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'text': data['message']['content'] as String,
          'audio_url': data['audio_url'] as String?,
          'tts_active': data['tts_active'] as bool? ?? false,
        };
      } else {
        throw Exception('Errore risposta backend (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
