import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/model_info.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  String _searchQuery = '';
  ModelType? _selectedTypeFilter;
  String _activeModelId = 'llama3_local';

  // Lista mock di modelli locali (Ollama) e cloud
  final List<ModelInfo> _models = [
    const ModelInfo(
      id: 'llama3_local',
      name: 'Llama 3 (8B)',
      provider: 'Ollama (Local)',
      type: ModelType.local,
      status: ModelStatus.active,
      size: '4.7 GB',
      description: 'Modello local-first bilanciato ottimale per coding e ragionamento veloce offline.',
    ),
    const ModelInfo(
      id: 'mistral_local',
      name: 'Mistral (7B)',
      provider: 'Ollama (Local)',
      type: ModelType.local,
      status: ModelStatus.downloaded,
      size: '4.1 GB',
      description: 'Modello compatto ad alte prestazioni, consigliato per hardware locale con VRAM limitata.',
    ),
    const ModelInfo(
      id: 'phi3_local',
      name: 'Phi-3 Medium',
      provider: 'Ollama (Local)',
      type: ModelType.local,
      status: ModelStatus.online,
      size: '7.9 GB',
      description: 'Modello locale di Microsoft con eccezionali abilità logiche per dimensioni ridotte.',
    ),
    const ModelInfo(
      id: 'qwen2_local',
      name: 'Qwen 2 (7B)',
      provider: 'Ollama (Local)',
      type: ModelType.local,
      status: ModelStatus.downloading,
      size: '4.4 GB',
      downloadProgress: 0.65,
      description: 'Ottime performance in coding multilingua e istruzioni complesse.',
    ),
    const ModelInfo(
      id: 'gpt4_cloud',
      name: 'GPT-4o',
      provider: 'OpenAI (Cloud)',
      type: ModelType.cloud,
      status: ModelStatus.online,
      size: 'API Cloud',
      description: 'Il modello cloud di riferimento per problemi di sviluppo complessi ed analisi avanzata.',
    ),
    const ModelInfo(
      id: 'claude3_cloud',
      name: 'Claude 3.5 Sonnet',
      provider: 'Anthropic (Cloud)',
      type: ModelType.cloud,
      status: ModelStatus.online,
      size: 'API Cloud',
      description: 'Eccellente nella comprensione e generazione di codice strutturato e refactoring.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filtraggio dinamico dei modelli
    final filteredModels = _models.where((model) {
      final matchesSearch = model.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          model.provider.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedTypeFilter == null || model.type == _selectedTypeFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo sezione
            Text(
              'GESTIONE MODELLI INTELLIGENTI',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Search Bar ed elegante barra dei filtri
            _buildSearchAndFilters(),
            const SizedBox(height: AppSpacing.md),

            // Lista Modelli
            Expanded(
              child: filteredModels.isEmpty
                  ? const _EmptyModelsView()
                  : ListView.builder(
                      itemCount: filteredModels.length,
                      itemBuilder: (context, index) {
                        final model = filteredModels[index];
                        final isActive = model.id == _activeModelId;

                        return _ModelTile(
                          model: model,
                          isActive: isActive,
                          onActivate: () {
                            if (model.status == ModelStatus.downloaded ||
                                model.status == ModelStatus.active ||
                                model.type == ModelType.cloud) {
                              setState(() {
                                _activeModelId = model.id;
                              });
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search text field
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Cerca modello per nome o provider...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Filtri chips orizzontali
        Row(
          children: [
            _FilterChip(
              label: 'Tutti',
              isSelected: _selectedTypeFilter == null,
              onSelected: () => setState(() => _selectedTypeFilter = null),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Locali (Ollama)',
              isSelected: _selectedTypeFilter == ModelType.local,
              onSelected: () => setState(() => _selectedTypeFilter = ModelType.local),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Cloud APIs',
              isSelected: _selectedTypeFilter == ModelType.cloud,
              onSelected: () => setState(() => _selectedTypeFilter = ModelType.cloud),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom Filter Chip.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusCircular,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

/// Card rappresentativa per singolo modello IA.
class _ModelTile extends StatelessWidget {
  final ModelInfo model;
  final bool isActive;
  final VoidCallback onActivate;

  const _ModelTile({
    required this.model,
    required this.isActive,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = model.type == ModelType.local;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        borderColor: isActive ? AppColors.primary : AppColors.border,
        borderWidth: isActive ? 1.5 : 1.0,
        backgroundColor: isActive ? AppColors.surfaceElevated : AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Informazioni principali ed etichetta tipo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLocal
                            ? AppColors.localModel.withValues(alpha: 0.15)
                            : AppColors.cloudModel.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderRadiusSm,
                        border: Border.all(
                          color: isLocal
                              ? AppColors.localModel.withValues(alpha: 0.4)
                              : AppColors.cloudModel.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isLocal ? 'LOCAL (OLLAMA)' : 'CLOUD',
                        style: GoogleFonts.rajdhani(
                          color: isLocal ? AppColors.localModel : AppColors.cloudModel,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      model.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),

                // Stato o Bottone di azione
                _buildStatusOrActionButton(context),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Descrizione del modello
            Text(
              model.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // File size o metadati e stato di avanzamento download
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Provider: ${model.provider}  •  Dimensione: ${model.size}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                if (model.status == ModelStatus.downloading && model.downloadProgress != null)
                  Text(
                    'Downloading: ${(model.downloadProgress! * 100).toInt()}%',
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
              ],
            ),
            if (model.status == ModelStatus.downloading && model.downloadProgress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadius.borderRadiusSm,
                child: LinearProgressIndicator(
                  value: model.downloadProgress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 4,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOrActionButton(BuildContext context) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: AppRadius.borderRadiusCircular,
          border: Border.all(color: AppColors.success),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: AppColors.success, size: 12),
            SizedBox(width: 4),
            Text(
              'Attivo',
              style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    switch (model.status) {
      case ModelStatus.online:
        if (model.type == ModelType.cloud) {
          // Cloud models non hanno download locale, sono pronti all'attivazione
          return OutlinedButton(
            onPressed: onActivate,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              side: const BorderSide(color: AppColors.primary),
            ),
            child: const Text('Attiva', style: TextStyle(color: AppColors.primary, fontSize: 11)),
          );
        }
        return IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.textSecondary),
          onPressed: () {},
        );
      case ModelStatus.downloading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        );
      case ModelStatus.downloaded:
      case ModelStatus.active:
        return OutlinedButton(
          onPressed: onActivate,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            side: const BorderSide(color: AppColors.primary),
          ),
          child: const Text('Attiva', style: TextStyle(color: AppColors.primary, fontSize: 11)),
        );
    }
  }
}

class _EmptyModelsView extends StatelessWidget {
  const _EmptyModelsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dns_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nessun modello trovato',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prova a modificare la ricerca o il filtro attivo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
