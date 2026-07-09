import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/graphing/graph_controller.dart';
import 'package:scientific_calculator/graphing/graph_mode.dart';

void main() {
  group('GraphController', () {
    test('starts with exactly one empty plot', () {
      final controller = GraphController();
      expect(controller.plots, hasLength(1));
      expect(controller.plots.single.isEmpty, isTrue);
    });

    test('addPlot appends up to the color palette limit', () {
      final controller = GraphController();
      final before = controller.plots.length;
      controller.addPlot();
      expect(controller.plots.length, before + 1);
    });

    test('removePlot refuses to remove the last plot', () {
      final controller = GraphController();
      controller.removePlot(controller.plots.single.id);
      expect(controller.plots, hasLength(1));
    });

    test('switching mode clears the plot list for the new mode', () {
      final controller = GraphController();
      controller.updatePrimaryExpression(controller.plots.single.id, 'x^2');
      controller.setMode(GraphMode.polar);
      expect(controller.mode, GraphMode.polar);
      expect(controller.plots.single.primaryExpression, isEmpty);
    });

    test('sampling a valid function produces segments', () {
      final controller = GraphController();
      controller.updatePrimaryExpression(controller.plots.single.id, 'x');
      final segments = controller.segmentsFor(controller.plots.single);
      expect(segments, isNotEmpty);
    });

    test('table generates x/y rows for a function plot', () {
      final controller = GraphController();
      controller.updatePrimaryExpression(controller.plots.single.id, 'x^2');
      final rows = controller.tableFor(controller.plots.single, start: 0, step: 1, count: 4);
      expect(rows.map((r) => r.output), [0, 1, 4, 9]);
    });

    test('pan and zoom update the viewport', () {
      final controller = GraphController();
      final initial = controller.viewport;
      controller.pan(1, 1);
      expect(controller.viewport.xMin, initial.xMin + 1);
      controller.zoom(0.5);
      expect(controller.viewport.width, lessThan(initial.width));
    });
  });
}
