import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import 'language_picker_screen.dart';
import '../services/settings_controller.dart';
import '../theme/layout_style.dart';
import '../theme/vision_profile.dart';
import '../widgets/look_pickers.dart';

// TODO: swap for a permanently-hosted URL before publishing — this one is
// a Claude Artifact, convenient for getting a real, live URL in front of
// Play Console today, but not a long-term hosting home.
const privacyPolicyUrl = 'https://claude.ai/code/artifact/3e3eef04-1156-4f39-9f5b-463168598093';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final strings = L10n.stringsOf(context);
        final language = settings.language;
        return Scaffold(
          appBar: AppBar(title: Text(strings.settings)),
          body: SingleChildScrollView(
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(strings.language, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: Text(language?.flag ?? '🌐', style: const TextStyle(fontSize: 28)),
                title: Text(strings.language),
                subtitle: Text(language?.listLabel ?? strings.searchLanguages),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LanguagePickerScreen(settings: settings),
                  ),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(strings.layout, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              RadioGroup<LayoutStyle>(
                groupValue: settings.layoutStyle,
                onChanged: (value) {
                  if (value != null) settings.setLayoutStyle(value);
                },
                child: Column(
                  children: [
                    for (final style in LayoutStyle.values)
                      RadioListTile<LayoutStyle>(
                        value: style,
                        title: Text(style.label),
                        subtitle: Text(style.description),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(strings.look, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(strings.lookHint, style: Theme.of(context).textTheme.bodySmall),
              ),
              if (settings.visionProfile == VisionProfile.highContrastColorBlind ||
                  settings.layoutStyle == LayoutStyle.accessible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(strings.lookPaused, style: Theme.of(context).textTheme.bodySmall),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ColorStoryPicker(
                  value: settings.colorStory,
                  onChanged: settings.setColorStory,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(strings.typeface, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(strings.typefaceHint, style: Theme.of(context).textTheme.bodySmall),
              ),
              TypeVoicePicker(
                value: settings.typeVoice,
                onChanged: settings.setTypeVoice,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(strings.vision, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              RadioGroup<VisionProfile>(
                groupValue: settings.visionProfile,
                onChanged: (value) {
                  if (value != null) settings.setVisionProfile(value);
                },
                child: Column(
                  children: [
                    for (final profile in VisionProfile.values)
                      RadioListTile<VisionProfile>(
                        value: profile,
                        title: Text(profile.label),
                        subtitle: Text(profile.description),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(strings.textSize),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1.0, label: Text('Default'), tooltip: 'Default text size'),
                      ButtonSegment(value: 1.25, label: Text('Large'), tooltip: 'Large text'),
                      ButtonSegment(value: 1.5, label: Text('Extra large'), tooltip: 'Extra large text'),
                    ],
                    selected: {settings.textScale},
                    onSelectionChanged: (s) => settings.setTextScale(s.first),
                    showSelectedIcon: true,
                  ),
                ),
              ),
              SwitchListTile(
                title: Text(strings.openLast),
                subtitle: Text(strings.openLastHint),
                value: settings.openLastMode,
                onChanged: settings.setOpenLastMode,
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Button feedback', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: Text(strings.sound),
                subtitle: const Text('Useful for low-vision users, off by default'),
                value: settings.soundEnabled,
                onChanged: settings.setSoundEnabled,
              ),
              SwitchListTile(
                title: Text(strings.haptics),
                value: settings.hapticsEnabled,
                onChanged: settings.setHapticsEnabled,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(strings.about, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const _AboutSection(),
            ],
            ),
          ),
        );
      },
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(L10n.stringsOf(context).privacy),
          subtitle: const Text('This app collects no personal data — read the full policy'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
        ),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            return ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(L10n.stringsOf(context).version),
              subtitle: Text(info == null ? 'Loading…' : '${info.version} (build ${info.buildNumber})'),
            );
          },
        ),
      ],
    );
  }
}
