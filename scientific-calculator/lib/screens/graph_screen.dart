import 'package:flutter/material.dart' hide Offset;

import '../core/angle_mode.dart';
import '../graphing/graph_controller.dart';
import '../graphing/graph_mode.dart';
import '../graphing/graph_painter.dart';
import '../graphing/plot_definition.dart';
import '../theme/app_theme.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key, GraphController? controller}) : _injectedController = controller;

  /// Exposed for tests that need to verify a simulated gesture actually
  /// reached the controller (rather than just "no exception was thrown",
  /// which the TabBarView gesture-arena bug this app shipped with would
  /// have passed too — the bug was a silent no-op, not a crash).
  final GraphController? _injectedController;

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  late final _controller = widget._injectedController ?? GraphController();
  bool _showTable = false;

  @override
  void dispose() {
    // Only dispose a controller this screen created itself — an injected
    // controller is owned by whoever passed it in (e.g. a test).
    if (widget._injectedController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _ModeBar(controller: _controller),
            _ExpressionList(controller: _controller),
            if (_controller.mode == GraphMode.parametric || _controller.mode == GraphMode.sequence)
              _DomainRow(controller: _controller),
            _ControlBar(
              controller: _controller,
              showTable: _showTable,
              onToggleTable: () => setState(() => _showTable = !_showTable),
            ),
            Expanded(
              child: _showTable
                  ? _TableView(controller: _controller)
                  : _GraphCanvas(controller: _controller),
            ),
          ],
        );
      },
    );
  }
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({required this.controller});

  final GraphController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SegmentedButton<GraphMode>(
        segments: [
          for (final mode in GraphMode.values)
            ButtonSegment(value: mode, label: Text(mode.label)),
        ],
        selected: {controller.mode},
        onSelectionChanged: (selection) => controller.setMode(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class _ExpressionList extends StatelessWidget {
  const _ExpressionList({required this.controller});

  final GraphController controller;

  @override
  Widget build(BuildContext context) {
    final mode = controller.mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          for (final plot in controller.plots) _PlotRow(controller: controller, plot: plot, mode: mode),
          if (controller.plots.length < plotColors.length)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.addPlot,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add ${mode.prefix.replaceAll('=', '')}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlotRow extends StatelessWidget {
  const _PlotRow({required this.controller, required this.plot, required this.mode});

  final GraphController controller;
  final PlotDefinition plot;
  final GraphMode mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              plot.visible ? Icons.circle : Icons.circle_outlined,
              color: plot.color,
            ),
            tooltip: plot.visible ? 'Hide' : 'Show',
            onPressed: () => controller.toggleVisible(plot.id),
          ),
          if (mode == GraphMode.parametric) ...[
            Expanded(
              child: _ExpressionField(
                key: ValueKey('${plot.id}-x'),
                prefix: 'x(t)=',
                initialValue: plot.primaryExpression,
                onChanged: (v) => controller.updatePrimaryExpression(plot.id, v),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ExpressionField(
                key: ValueKey('${plot.id}-y'),
                prefix: 'y(t)=',
                initialValue: plot.secondaryExpression,
                onChanged: (v) => controller.updateSecondaryExpression(plot.id, v),
              ),
            ),
          ] else
            Expanded(
              child: _ExpressionField(
                key: ValueKey(plot.id),
                prefix: mode.prefix,
                initialValue: plot.primaryExpression,
                onChanged: (v) => controller.updatePrimaryExpression(plot.id, v),
                errorText: plot.error,
              ),
            ),
          if (controller.plots.length > 1)
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              tooltip: 'Remove',
              onPressed: () => controller.removePlot(plot.id),
            ),
        ],
      ),
    );
  }
}

class _ExpressionField extends StatelessWidget {
  const _ExpressionField({
    super.key,
    required this.prefix,
    required this.initialValue,
    required this.onChanged,
    this.errorText,
  });

  final String prefix;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        prefixText: prefix,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({required this.controller});

  final GraphController controller;

  @override
  Widget build(BuildContext context) {
    final isSequence = controller.mode == GraphMode.sequence;
    final min = isSequence ? controller.sequenceMin : controller.paramMin;
    final max = isSequence ? controller.sequenceMax : controller.paramMax;
    final label = isSequence ? 'n' : 't';

    void apply(double newMin, double newMax) {
      if (isSequence) {
        controller.setSequenceDomain(newMin, newMax);
      } else {
        controller.setParamDomain(newMin, newMax);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // Two labelled fields do not fit on one line at phone width, and a
      // fixed Row has no way to say so. Wrapping lets the second pair drop
      // to a new line instead of running off the edge — and it is what
      // keeps them reachable once the text size grows, too.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text('$label min', style: Theme.of(context).textTheme.labelSmall),
          SizedBox(
            width: 70,
            child: TextFormField(
              key: ValueKey('domain-min-${controller.mode}'),
              initialValue: _formatNum(min),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              onFieldSubmitted: (v) => apply(double.tryParse(v) ?? min, max),
            ),
          ),
          Text('$label max', style: Theme.of(context).textTheme.labelSmall),
          SizedBox(
            width: 70,
            child: TextFormField(
              key: ValueKey('domain-max-${controller.mode}'),
              initialValue: _formatNum(max),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              onFieldSubmitted: (v) => apply(min, double.tryParse(v) ?? max),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.controller,
    required this.showTable,
    required this.onToggleTable,
  });

  final GraphController controller;
  final bool showTable;
  final VoidCallback onToggleTable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      // Three icon buttons, a view toggle and an angle-mode control do not
      // fit on one line at phone width, and a Spacer cannot report that —
      // it just pushes the last control off the edge. Wrapping lets the
      // row become two, which is also what has to happen when the text
      // size grows.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 4,
        runSpacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom in',
            onPressed: () => controller.zoom(0.7),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom out',
            onPressed: () => controller.zoom(1.4),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset view',
            onPressed: controller.resetViewport,
          ),
          if (controller.mode == GraphMode.function)
            TextButton.icon(
              onPressed: onToggleTable,
              icon: Icon(showTable ? Icons.show_chart : Icons.table_chart),
              label: Text(showTable ? 'Graph' : 'Table'),
            ),
          SegmentedButton<AngleMode>(
            segments: const [
              ButtonSegment(value: AngleMode.radians, label: Text('RAD')),
              ButtonSegment(value: AngleMode.degrees, label: Text('DEG')),
            ],
            selected: {controller.angleMode},
            onSelectionChanged: (s) => controller.setAngleMode(s.first),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

class _GraphCanvas extends StatelessWidget {
  const _GraphCanvas({required this.controller});

  final GraphController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          key: const Key('graph-canvas'),
          // A bare CustomPaint (no child) doesn't claim hit-tests itself, so
          // without `opaque` this detector's deferToChild default would
          // never see pointer events at all — pan/zoom would silently do
          // nothing.
          behavior: HitTestBehavior.opaque,
          onScaleUpdate: (details) {
            if ((details.scale - 1.0).abs() > 0.01) {
              controller.zoom(1 / details.scale);
            } else {
              final unitsPerPxX = controller.viewport.width / size.width;
              final unitsPerPxY = controller.viewport.height / size.height;
              controller.pan(
                -details.focalPointDelta.dx * unitsPerPxX,
                details.focalPointDelta.dy * unitsPerPxY,
              );
            }
          },
          child: Semantics(
            label: 'Graph canvas. Use the zoom and reset controls above for precise navigation.',
            child: CustomPaint(
              size: size,
              painter: GraphPainter(
                viewport: controller.viewport,
                plots: controller.plots,
                segmentsOf: controller.segmentsFor,
                axisColor: palette.label.withValues(alpha: 0.8),
                gridColor: palette.separator,
                labelColor: palette.secondaryLabel,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({required this.controller});

  final GraphController controller;

  @override
  Widget build(BuildContext context) {
    final functionPlots = controller.plots.where((p) => p.primaryExpression.trim().isNotEmpty).toList();
    if (functionPlots.isEmpty) {
      return const Center(child: Text('Enter a function above to see its table.'));
    }
    return DefaultTabController(
      length: functionPlots.length,
      child: Column(
        children: [
          if (functionPlots.length > 1)
            TabBar(
              isScrollable: true,
              tabs: [for (final p in functionPlots) Tab(text: p.primaryExpression)],
            ),
          Expanded(
            child: TabBarView(
              children: [
                for (final plot in functionPlots) _SingleTable(controller: controller, plot: plot),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleTable extends StatelessWidget {
  const _SingleTable({required this.controller, required this.plot});

  final GraphController controller;
  final PlotDefinition plot;

  @override
  Widget build(BuildContext context) {
    final rows = controller.tableFor(plot, start: controller.viewport.xMin, step: 1, count: 30);
    return ListView.builder(
      itemCount: rows.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('x', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('y', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }
        final row = rows[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(row.input.toStringAsFixed(2))),
              Expanded(child: Text(row.output == null ? 'undefined' : row.output!.toStringAsFixed(4))),
            ],
          ),
        );
      },
    );
  }
}
