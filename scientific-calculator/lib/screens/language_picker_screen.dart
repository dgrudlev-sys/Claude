import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../l10n/l10n.dart';
import '../services/settings_controller.dart';

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
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final lang = matches[index];
                        final selected = current?.code == lang.code;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            button: true,
                            selected: selected,
                            label: '${lang.semanticLabel}${selected ? ', selected' : ''}',
                            child: Material(
                              color: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  width: selected ? 3 : 1,
                                ),
                              ),
                              child: InkWell(
                                key: Key('lang-${lang.code}'),
                                onTap: () async {
                                  await widget.settings.setLanguage(lang);
                                  widget.onPicked?.call();
                                  if (context.mounted && !widget.asFirstLaunch) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 64),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Text(lang.flag, style: const TextStyle(fontSize: 28)),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            lang.titleLine,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        if (selected) const Icon(Icons.check, size: 28),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
