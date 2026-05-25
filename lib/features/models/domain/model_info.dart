enum ModelType { local, cloud }

enum ModelStatus { active, downloaded, online, downloading }

/// Rappresenta le informazioni di un modello LLM da mostrare nel Picker.
class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final ModelType type;
  final ModelStatus status;
  final String size;
  final double? downloadProgress;
  final String description;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    required this.status,
    required this.size,
    this.downloadProgress,
    required this.description,
  });

  ModelInfo copyWith({
    String? id,
    String? name,
    String? provider,
    ModelType? type,
    ModelStatus? status,
    String? size,
    double? downloadProgress,
    String? description,
  }) {
    return ModelInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      type: type ?? this.type,
      status: status ?? this.status,
      size: size ?? this.size,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      description: description ?? this.description,
    );
  }
}
