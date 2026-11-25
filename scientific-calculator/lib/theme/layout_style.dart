/// The visual/keypad skins a user can pick between. All three share the
/// same button set and math logic — only density, sizing, and contrast
/// change, so accessibility is a first-class layout choice, not a bolt-on
/// afterthought. The number pad is always 4 columns; [columns] is a density
/// hint for chrome, not a reason to rescale the Samsung numpad.
enum LayoutStyle {
  classic(
    label: 'Classic',
    description: 'Familiar TI-style key layout and proportions.',
    columns: 5,
    fontScale: 1.0,
    minTouchTarget: 48,
  ),
  compact(
    label: 'Compact',
    description: 'Denser spacing, more display space.',
    columns: 5,
    fontScale: 0.92,
    minTouchTarget: 48,
  ),
  accessible(
    label: 'Large & high-contrast',
    description: 'Bigger 56dp touch targets, larger type, fewer columns.',
    columns: 4,
    fontScale: 1.35,
    minTouchTarget: 56,
  );

  const LayoutStyle({
    required this.label,
    required this.description,
    required this.columns,
    required this.fontScale,
    required this.minTouchTarget,
  });

  final String label;
  final String description;
  final int columns;
  final double fontScale;
  final double minTouchTarget;
}
