import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../l10n/l10n.dart';
import '../services/settings_controller.dart';
import '../theme/app_metrics.dart';
import '../widgets/chooser_tile.dart';

/// Accessible language picker: large rows, flags, English · Native titles,
/// and a single search box that matches both English and native names.
class LanguagePickerScreen extends StatefulWidget {
  const LanguagePickerScreen({
    super.key,
    required this.settings,
    this.onPicked,
    this.asFirstLaunch = false,
  });

  final SettingsController settings;
  final VoidCallback? onPicked;
  final bool asFirstLaunch;

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.maybeOf(context)?.strings ?? AppStrings.of(AppLanguage.english);
    final matches = AppLanguage.supported.where((l) => l.matches(_query)).toList();
    final current = widget.settings.language;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.asFirstLaunch,
        title: Text(strings.language),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(strings.languageHint, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                textField: true,
                label: strings.searchLanguages,
                child: TextField(
                  key: const Key('language-search'),
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: strings.searchLanguages,
                    hintText: 'Bulgarian · български',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text(strings.noLanguages))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppMetrics.space4),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const ChooserDivider(),
                      itemBuilder: (context, index) {
                        final lang = matches[index];
                        final selected = current?.code == lang.code;
                        return ChooserTile(
                          key: Key('lang-${lang.code}'),
                          leading: SizedBox(
                            width: AppMetrics.glyphSize,
                            height: AppMetrics.glyphSize,
                            child: Align(
                              child: Text(lang.flag, style: const TextStyle(fontSize: AppMetrics.glyphSize)),
                            ),
                          ),
                          title: lang.titleLine,
                          selected: selected,
                          onTap: () async {
                            await widget.settings.setLanguage(lang);
                            widget.onPicked?.call();
                            if (context.mounted && !widget.asFirstLaunch) {
                              Navigator.of(context).pop();
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
}
