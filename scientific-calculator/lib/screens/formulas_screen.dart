import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/typography.dart';
import '../navigation/tool_catalog.dart';
import '../services/settings_controller.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// Formulas & Tools: everything the app can do, grouped and searchable.
///
/// One screen renders every level of the tree. A group pushes another
/// copy of this screen with its children; a leaf opens the tool. That is
/// why the catalog is data — a second screen per depth would be three
/// screens that have to be kept looking alike, and they never do.
class FormulasScreen extends StatefulWidget {
  const FormulasScreen({
    super.key,
    required this.settings,
    this.title = 'Formulas & Tools',
    this.blurb =
        'Explore formulas, categories and tools to help you calculate, '
            'solve and learn.',
    this.nodes = toolCatalog,
    this.isRoot = true,
  });

  final SettingsController settings;
  final String title;
  final String? blurb;
  final List<ToolNode> nodes;

  /// The root gets the large title and the blurb; a pushed level gets an
  /// ordinary bar with a back button, as the mock shows.
  final bool isRoot;

  @override
  State<FormulasScreen> createState() => _FormulasScreenState();
}

class _FormulasScreenState extends State<FormulasScreen> {
  String _query = '';

  void _open(ToolNode node) {
    switch (node) {
      case ToolGroup():
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(node.title)),
              body: FormulasScreen(
                settings: widget.settings,
                title: node.title,
                blurb: null,
                nodes: node.children,
                isRoot: false,
              ),
            ),
          ),
        );
      case ToolEntry(:final mode):
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ModeScaffold(mode: mode, settings: widget.settings),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final results = searchTools(_query);
    final searching = _query.trim().isNotEmpty;

    return SafeArea(
      child: PageBody(
        children: [
          if (widget.isRoot) ...[
            Padding(
              padding: const EdgeInsets.only(top: Space.s, bottom: Space.xs),
              child: Text(
                widget.title,
                style: AppType.largeTitle.copyWith(color: palette.label),
              ),
            ),
            if (widget.blurb != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.m),
                child: Text(
                  widget.blurb!,
                  style: AppType.subheadline
                      .copyWith(color: palette.secondaryLabel),
                ),
              ),
          ],
          SearchField(
            hint: 'Search formulas, topics or tools…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: Space.l),
          if (searching) ...[
            SectionLabel(
              results.isEmpty
                  ? 'Nothing matches “${_query.trim()}”'
                  : '${results.length} '
                      '${results.length == 1 ? 'result' : 'results'}',
            ),
            for (var i = 0; i < results.length; i++) ...[
              CategoryRow(
                title: results[i].title,
                subtitle: results[i].summary,
                icon: results[i].icon,
                tintIndex: i,
                onTap: () => _open(results[i]),
              ),
              const SizedBox(height: Space.s),
            ],
          ] else
            for (var i = 0; i < widget.nodes.length; i++) ...[
              CategoryRow(
                title: widget.nodes[i].title,
                subtitle: widget.nodes[i].summary,
                icon: widget.nodes[i].icon,
                tintIndex: i,
                onTap: () => _open(widget.nodes[i]),
              ),
              const SizedBox(height: Space.s),
            ],
        ],
      ),
    );
  }
}
