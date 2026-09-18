import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/settings_controller.dart';
import '../theme/app_theme.dart';
import '../theme/layout_style.dart';
import 'home_shell.dart';

// TODO: swap for a permanently-hosted URL before publishing — this one is
// a Claude Artifact, convenient for getting a real, live URL in front of
// Play Console today, but not a long-term hosting home.
const privacyPolicyUrl = 'https://claude.ai/code/artifact/3e3eef04-1156-4f39-9f5b-463168598093';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    this.embedded = false,
  });

  final SettingsController settings;

  /// True when this is a tab in the shell, which already supplies the
  /// surrounding chrome. A Scaffold inside a Scaffold would put a second
  /// bar under the first one.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Layout', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Button feedback', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text('Sound on key press'),
                subtitle: const Text('Useful for low-vision users, off by default'),
                value: settings.soundEnabled,
                onChanged: settings.setSoundEnabled,
              ),
              SwitchListTile(
                title: const Text('Vibration on key press'),
                value: settings.hapticsEnabled,
                onChanged: settings.setHapticsEnabled,
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const _AboutSection(),
            ],
          );
        },
      );

    if (embedded) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Space.m),
              child: TabTitle('Settings'),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: body,
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
          title: const Text('Privacy policy'),
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
              title: const Text('Version'),
              subtitle: Text(info == null ? 'Loading…' : '${info.version} (build ${info.buildNumber})'),
            );
          },
        ),
      ],
    );
  }
}
