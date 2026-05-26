import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/state/assistant_state.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/model_info.dart';

class ModelsScreen extends StatefulWidget {
  final AssistantState state;

  const ModelsScreen({
    super.key,
    required this.state,
  });

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  String _searchQuery = '';
  ModelType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    // Raggruppa e filtra la lista dei modelli caricata dallo stato dell'app
    final filteredModels = widget.state.models.where((model) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GESTIONE MODELLI INTELLIGENTI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                ),
                // Icona di caricamento modelli
                if (widget.state.isLoadingModels)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                    onPressed: () => widget.state.refreshModels(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Filtro e barra di ricerca
            _buildSearchAndFilters(),
            const SizedBox(height: AppSpacing.md),

            // Lista Modelli
            Expanded(
              child: filteredModels.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: filteredModels.length,
                      itemBuilder: (context, index) {
                        final model = filteredModels[index];
                        final isActive = widget.state.activeModel?.id == model.id;

                        return _ModelTile(
                          model: model,
                          isActive: isActive,
                          onActivate: () {
                            widget.state.selectModel(model);
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
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Filtri chips
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dns_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.state.isConnected ? 'Nessun modello trovato' : 'Ollama Offline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.state.isConnected 
                ? 'Prova a modificare la ricerca o il filtro attivo.' 
                : 'Accendi Ollama sul tuo PC locale per elencare i modelli.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

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
                // Info principali ed etichetta tipo
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLocal ? Icons.computer : Icons.cloud_queue, 
                            color: isLocal ? AppColors.localModel : AppColors.cloudModel,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLocal ? 'LOCAL' : 'CLOUD',
                            style: GoogleFonts.rajdhani(
                              color: isLocal ? AppColors.localModel : AppColors.cloudModel,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
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

                // Stato / Attiva
                _buildStatusOrActionButton(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Descrizione
            Text(
              model.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Info finali
            Text(
              'Provider: ${model.provider}  •  Dimensione: ${model.size}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOrActionButton() {
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

    return OutlinedButton(
      onPressed: onActivate,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        side: BorderSide(color: AppColors.primary),
      ),
      child: Text('Attiva', style: TextStyle(color: AppColors.primary, fontSize: 11)),
    );
  }
}
