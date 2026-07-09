import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/graphing/graph_viewport.dart';

void main() {
  group('GraphViewport', () {
    test('pan translates both axes', () {
      const v = GraphViewport(xMin: -10, xMax: 10, yMin: -5, yMax: 5);
      final panned = v.pan(2, -1);
      expect(panned.xMin, -8);
      expect(panned.xMax, 12);
      expect(panned.yMin, -6);
      expect(panned.yMax, 4);
    });

    test('zoom in shrinks the window around its center', () {
      const v = GraphViewport(xMin: -10, xMax: 10, yMin: -10, yMax: 10);
      final zoomed = v.zoom(0.5);
      expect(zoomed.xMin, -5);
      expect(zoomed.xMax, 5);
      expect(zoomed.yMin, -5);
      expect(zoomed.yMax, 5);
    });

    test('zoom out grows the window around its center', () {
      const v = GraphViewport(xMin: -4, xMax: 4, yMin: -4, yMax: 4);
      final zoomed = v.zoom(2);
      expect(zoomed.xMin, -8);
      expect(zoomed.xMax, 8);
    });

    test('niceStep picks human-friendly spacing', () {
      expect(GraphViewport.niceStep(20, targetLines: 8), closeTo(2, 1e-9));
      expect(GraphViewport.niceStep(1000, targetLines: 10), closeTo(100, 1e-9));
      expect(GraphViewport.niceStep(1, targetLines: 8), closeTo(0.1, 1e-9));
    });
  });
}
