import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/models/domain/model_info.dart';

/// Servizio di interfaccia con le API locali/remote di Ollama.
class OllamaService {
  String baseUrl;

  OllamaService({this.baseUrl = 'http://localhost:11434/api'});

  /// Recupera la lista dei modelli locali installati su Ollama.
  Future<List<ModelInfo>> fetchLocalModels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tags')).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> modelsJson = data['models'] ?? [];

        return modelsJson.map((m) {
          final name = m['name'] as String;
          // Calcola la dimensione del file in GB o MB leggibili
          final sizeInBytes = m['size'] as int? ?? 0;
          final double sizeInGb = sizeInBytes / (1024 * 1024 * 1024);
          final sizeStr = sizeInGb > 0.1 
              ? '${sizeInGb.toStringAsFixed(2)} GB' 
              : '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(0)} MB';

          return ModelInfo(
            id: name,
            name: name,
            provider: 'Ollama (Locale)',
            type: ModelType.local,
            status: ModelStatus.downloaded,
            size: sizeStr,
            description: 'Modello locale caricato ed eseguito direttamente tramite Ollama.',
          );
        }).toList();
      } else {
        throw Exception('Risposta non valida da Ollama: ${response.statusCode}');
      }
    } catch (e) {
      // In caso di errore di connessione (es. Ollama spento), propaghiamo l'eccezione
      rethrow;
    }
  }

  /// Invia la cronologia dei messaggi alla chat di Ollama e restituisce la risposta dell'assistente.
  Future<String> sendChatMessage(String model, List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'messages': messages,
          'stream': false, // Semplificato senza streaming per una UI robusta ed immediata
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['message']['content'] as String;
      } else {
        throw Exception('Errore risposta Ollama (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
