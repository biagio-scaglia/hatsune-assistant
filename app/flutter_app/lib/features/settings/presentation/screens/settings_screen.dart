import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/state/assistant_state.dart';
import '../../../../shared/widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final AssistantState state;

  const SettingsScreen({
    super.key,
    required this.state,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _hostController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.state.ollamaUrl);
    _apiKeyController = TextEditingController(text: widget.state.cloudApiKey);
    widget.state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _hostController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final url = _hostController.text.trim();
    if (url.isNotEmpty) {
      widget.state.setOllamaUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Endpoint Ollama aggiornato a: $url'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _saveApiKey() {
    final key = _apiKeyController.text.trim();
    widget.state.setCloudApiKey(key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chiave API Cloud salvata con successo'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IMPOSTAZIONI APPLICAZIONE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione Connettività Ollama / Cloud
            _SettingsSection(
              title: 'Configurazione Ollama & Cloud APIs',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Host Locale Ollama', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('L\'indirizzo ip del tuo server Ollama attivo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextFormField(
                                controller: _hostController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceElevated,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.borderRadiusSm,
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.borderRadiusSm,
                                    borderSide: BorderSide(color: AppColors.primary),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderRadiusSm,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _saveSettings,
                            child: const Text('Salva', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chiavi API Cloud', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Configura OpenAI o Anthropic keys (Predisposto)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextFormField(
                                controller: _apiKeyController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceElevated,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.borderRadiusSm,
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.borderRadiusSm,
                                    borderSide: BorderSide(color: AppColors.primary),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderRadiusSm,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _saveApiKey,
                            child: const Text('Salva', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione Appearance
            _SettingsSection(
              title: 'Aspetto & Personalizzazione',
              children: [
                _SettingsTileSwitch(
                  title: 'Abilita Neon Glow Borders',
                  subtitle: 'Aggiunge un leggero bagliore neon attorno alle card',
                  value: widget.state.neonGlowEnabled,
                  onChanged: (val) => widget.state.setNeonGlowEnabled(val),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tema Colori', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(widget.state.colorTheme, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    final nextTheme = widget.state.colorTheme == "Cyan Cyberpunk"
                        ? "Pink Cyberpunk"
                        : "Cyan Cyberpunk";
                    widget.state.setColorTheme(nextTheme);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione Assistant Behavior
            _SettingsSection(
              title: 'Comportamento Assistente',
              children: [
                _SettingsTileSwitch(
                  title: 'Modalità Vocale Abilitata',
                  subtitle: 'Miku risponde anche utilizzando il Text To Speech (Predisposto)',
                  value: widget.state.voiceModeEnabled,
                  onChanged: (val) => widget.state.setVoiceModeEnabled(val),
                ),
                _SettingsTileSlider(
                  title: 'Temperatura Creatività',
                  subtitle: 'Valori alti producono risposte più fantasiose',
                  value: widget.state.temperature,
                  onChanged: (val) => widget.state.setTemperature(val),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione Performance
            _SettingsSection(
              title: 'Prestazioni & Risorse',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Limite Contesto Token', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Impostato per risparmiare VRAM del server', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: Text(
                    widget.state.tokenContextLimit.toString(),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    final nextLimit = widget.state.tokenContextLimit == 4096
                        ? 8192
                        : (widget.state.tokenContextLimit == 8192 ? 2048 : 4096);
                    widget.state.setTokenContextLimit(nextLimit);
                  },
                ),
                _SettingsTileSwitch(
                  title: 'GPU Offloading locale',
                  subtitle: 'Utilizza l\'accelerazione grafica locale se disponibile',
                  value: widget.state.gpuOffloading,
                  onChanged: (val) => widget.state.setGpuOffloading(val),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione About
            _SettingsSection(
              title: 'Informazioni',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hatsune Assistant V1.2.0', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Made by biagigio. Hatsune Miku è un marchio registrato di Crypton Future Media.', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderRadiusSm,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text('STABLE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenitore per raggruppare i settings.
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ),
        GlassCard(
          borderColor: AppColors.border,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            children: children.map((widget) {
              final isLast = children.last == widget;
              if (isLast) return widget;
              return Column(
                children: [
                  widget,
                  const Divider(color: AppColors.border, height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTileSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsTileSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}

class _SettingsTileSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final ValueChanged<double>? onChanged;

  const _SettingsTileSlider({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
