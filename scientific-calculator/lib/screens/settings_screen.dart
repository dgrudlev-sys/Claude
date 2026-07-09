import 'package:flutter/material.dart';

import '../services/settings_controller.dart';
import '../theme/layout_style.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
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
            ],
          );
        },
      ),
    );
  }
}
