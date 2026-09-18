enum GraphMode {
  function('Function', 'y='),
  parametric('Parametric', 'x(t),y(t)='),
  polar('Polar', 'r='),
  sequence('Sequence', 'u(n)=');

  const GraphMode(this.label, this.prefix);

  final String label;
  final String prefix;
}
