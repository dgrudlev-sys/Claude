enum AngleMode {
  degrees('DEG'),
  radians('RAD');

  const AngleMode(this.label);

  final String label;

  AngleMode get toggled => this == degrees ? radians : degrees;
}
