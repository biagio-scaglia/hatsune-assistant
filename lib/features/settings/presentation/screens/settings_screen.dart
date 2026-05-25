import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

            // Sezione Appearance
            const _SettingsSection(
              title: 'Aspetto & Personalizzazione',
              children: [
                _SettingsTileSwitch(
                  title: 'Abilita Neon Glow Borders',
                  subtitle: 'Aggiunge un leggero bagliore neon attorno alle card',
                  value: true,
                ),
                _SettingsTile(
                  title: 'Tema Colori',
                  subtitle: 'Cyan Cyberpunk (Hatsune Miku standard)',
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione Connettività Ollama / Cloud
            const _SettingsSection(
              title: 'Configurazione Ollama & Cloud APIs',
              children: [
                _SettingsTileInput(
                  title: 'Host Locale Ollama',
                  subtitle: 'L\'indirizzo ip del tuo server Ollama attivo',
                  initialValue: 'http://localhost:11434',
                ),
                _SettingsTile(
                  title: 'Chiavi API Cloud',
                  subtitle: 'Configura OpenAI o Anthropic keys',
                  trailing: Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione Assistant Behavior
            const _SettingsSection(
              title: 'Comportamento Assistente',
              children: [
                _SettingsTileSwitch(
                  title: 'Modalità Vocale Abilitata',
                  subtitle: 'Miku risponde anche utilizzando il Text To Speech',
                  value: false,
                ),
                _SettingsTileSlider(
                  title: 'Temperatura Creatività',
                  subtitle: 'Valori alti producono risposte più fantasiose',
                  value: 0.7,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sezione Performance
            const _SettingsSection(
              title: 'Prestazioni & Risorse',
              children: [
                _SettingsTile(
                  title: 'Limite Contesto Token',
                  subtitle: 'Impostato a 4096 token per risparmiare VRAM',
                  trailing: Text('4096', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                _SettingsTileSwitch(
                  title: 'GPU Offloading locale',
                  subtitle: 'Utilizza l\'accelerazione grafica locale se disponibile',
                  value: true,
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
                  title: const Text('Hatsune Assistant V1.0.0', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Made by biagigio. Hatsune Miku è un marchio registrato di Crypton Future Media.', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderRadiusSm,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Text('STABLE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
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

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: trailing,
    );
  }
}

class _SettingsTileSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;

  const _SettingsTileSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      value: value,
      onChanged: (_) {},
      activeThumbColor: AppColors.primary,
    );
  }
}

class _SettingsTileSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;

  const _SettingsTileSlider({
    required this.title,
    required this.subtitle,
    required this.value,
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
                    onChanged: (_) {},
                  ),
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsTileInput extends StatelessWidget {
  final String title;
  final String subtitle;
  final String initialValue;

  const _SettingsTileInput({
    required this.title,
    required this.subtitle,
    required this.initialValue,
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
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: TextFormField(
              initialValue: initialValue,
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
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
