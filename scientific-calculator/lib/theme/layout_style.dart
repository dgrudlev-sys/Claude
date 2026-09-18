/// The visual/keypad skins a user can pick between. All three share the
/// same button set and math logic — only density, sizing, and contrast
/// change, so accessibility is a first-class layout choice, not a bolt-on
/// afterthought.
enum LayoutStyle {
  classic(
    label: 'Classic',
    description: 'Familiar TI-style key layout and proportions.',
    columns: 5,
    fontScale: 1.0,
  ),
  compact(
    label: 'Compact',
    description: 'Denser spacing, more display space.',
    columns: 5,
    fontScale: 0.92,
  ),
  accessible(
    label: 'Large & high-contrast',
    description: 'Bigger touch targets, higher contrast, fewer columns.',
    columns: 4,
    fontScale: 1.25,
  );

  const LayoutStyle({
    required this.label,
    required this.description,
    required this.columns,
    required this.fontScale,
  });

  final String label;
  final String description;
  final int columns;
  final double fontScale;
}
