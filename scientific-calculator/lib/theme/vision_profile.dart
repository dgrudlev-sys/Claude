/// Color / contrast profiles. Selection, errors, and tools must never be
/// conveyed by hue alone — every state also has a shape, label, or pattern.
///
/// Research applied (WCAG 2.2 + color-vision deficiency):
/// - Low vision: prefer near-black backgrounds with near-white text (contrast
///   ≥ 7:1, AAA for body text) and large targets; thin gray-on-black fails.
/// - Color blindness: Bang Wong / IBM palettes keep orange, sky blue, yellow,
///   and royal blue separable under protanopia, deuteranopia, and tritanopia.
///   Never use green vs red as the only success/error cue.
/// - APCA: yellow (#F0E442) on black is a strong large-text pair; white on
///   black remains the most robust for small labels.
enum VisionProfile {
  standard(
    label: 'Standard',
    description: 'Use the Look you picked. Colour is backed up by labels and icons.',
  ),
  highContrastColorBlind(
    label: 'High contrast, color-blind safe',
    description:
        'Black background, white text, yellow and blue accents from the Wong '
        'palette. Selected items use a thick border and a check mark, not color alone.',
  );

  const VisionProfile({required this.label, required this.description});

  final String label;
  final String description;
}
