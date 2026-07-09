import 'package:flutter/foundation.dart';

import '../core/angle_mode.dart';
import '../core/calculator_engine.dart';
import 'surface_sampler.dart';

class SurfaceController extends ChangeNotifier {
  SurfaceController({SurfaceSampler? sampler}) : _sampler = sampler ?? SurfaceSampler(CalculatorEngine());

  final SurfaceSampler _sampler;

  String expression = 'x^2 - y^2';
  double xMin = -3, xMax = 3, yMin = -3, yMax = 3;
  double azimuth = 0.7;
  double elevation = 0.5;
  double zoom = 1.0;
  int resolution = 22;

  SampledSurface? surface;
  String? error;

  void setExpression(String value) {
    expression = value;
    notifyListeners();
  }

  void rotate(double dAzimuth, double dElevation) {
    azimuth += dAzimuth;
    elevation = (elevation + dElevation).clamp(-1.5, 1.5);
    notifyListeners();
  }

  void setZoom(double value) {
    zoom = value.clamp(0.3, 3.0);
    notifyListeners();
  }

  void resetView() {
    azimuth = 0.7;
    elevation = 0.5;
    zoom = 1.0;
    notifyListeners();
  }

  void compute() {
    error = null;
    surface = null;
    try {
      surface = _sampler.sample(
        expression,
        AngleMode.radians,
        xMin: xMin,
        xMax: xMax,
        yMin: yMin,
        yMax: yMax,
        resolution: resolution,
      );
    } on CalculatorError catch (e) {
      error = e.message;
    }
    notifyListeners();
  }
}
