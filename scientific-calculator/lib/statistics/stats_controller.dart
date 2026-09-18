import 'package:flutter/foundation.dart';

import 'stats_engine.dart';

enum StatsTab { oneVar, regression, distributions }

enum DistributionKind { normalCdf, invNorm, binomialPdf, binomialCdf }

/// UI state for the statistics screen: the shared L1/L2 data lists, which
/// sub-tool is active, and the last result/error for each.
class StatsController extends ChangeNotifier {
  StatsTab tab = StatsTab.oneVar;

  String l1Text = '2, 4, 4, 4, 5, 5, 7, 9';
  String l2Text = '1, 2, 3, 4, 5, 6, 7, 8';

  RegressionKind regressionKind = RegressionKind.linear;
  DistributionKind distributionKind = DistributionKind.normalCdf;

  OneVarStats? oneVarResult;
  RegressionResult? regressionResult;
  double? distributionResult;
  String? error;

  List<double> _parseList(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => double.parse(s))
        .toList();
  }

  void setTab(StatsTab newTab) {
    tab = newTab;
    error = null;
    notifyListeners();
  }

  void setL1(String text) {
    l1Text = text;
    notifyListeners();
  }

  void setL2(String text) {
    l2Text = text;
    notifyListeners();
  }

  void setRegressionKind(RegressionKind kind) {
    regressionKind = kind;
    notifyListeners();
  }

  void setDistributionKind(DistributionKind kind) {
    distributionKind = kind;
    notifyListeners();
  }

  void computeOneVar() {
    error = null;
    oneVarResult = null;
    try {
      oneVarResult = StatsEngine.oneVar(_parseList(l1Text));
    } on StatsError catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not parse the data list';
    }
    notifyListeners();
  }

  void computeRegression() {
    error = null;
    regressionResult = null;
    try {
      final x = _parseList(l1Text);
      final y = _parseList(l2Text);
      regressionResult = switch (regressionKind) {
        RegressionKind.linear => StatsEngine.polynomial(x, y, 1),
        RegressionKind.quadratic => StatsEngine.polynomial(x, y, 2),
        RegressionKind.cubic => StatsEngine.polynomial(x, y, 3),
        RegressionKind.quartic => StatsEngine.polynomial(x, y, 4),
        RegressionKind.power => StatsEngine.power(x, y),
        RegressionKind.exponential => StatsEngine.exponential(x, y),
        RegressionKind.logarithmic => StatsEngine.logarithmic(x, y),
      };
    } on StatsError catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not parse the data lists';
    }
    notifyListeners();
  }

  void computeDistribution({
    required double a,
    required double b,
    required double mean,
    required double sd,
    required int n,
    required double p,
    required int k,
  }) {
    error = null;
    distributionResult = null;
    try {
      distributionResult = switch (distributionKind) {
        DistributionKind.normalCdf => StatsEngine.normalCdf(a, b, mean: mean, sd: sd),
        DistributionKind.invNorm => StatsEngine.invNorm(a, mean: mean, sd: sd),
        DistributionKind.binomialPdf => StatsEngine.binomialPdf(n, p, k),
        DistributionKind.binomialCdf => StatsEngine.binomialCdf(n, p, k),
      };
    } on StatsError catch (e) {
      error = e.message;
    }
    notifyListeners();
  }
}
