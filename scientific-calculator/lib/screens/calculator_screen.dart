import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../design/typography.dart';
import '../services/feedback_service.dart';
import '../services/settings_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/calculator_display.dart';
import '../widgets/hardware_keyboard_input.dart';
import '../widgets/keypad.dart';
import 'input_methods_screen.dart';

/// The calculator: a big readout, the ways into it, and the keys.
///
/// The three parts are stacked in the order the mock puts them, and the
/// middle one is the reason this screen was rebuilt. The other ways of
/// entering maths — speaking it, photographing it — used to live behind
/// an icon in the navigation bar, which is where you look for settings,
/// not for a microphone. They are now a row of their own directly under
/// the display, where the thing they produce will appear.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.settings, this.controller});

  final SettingsController settings;

  /// Supplied by the shell, so that the History tab is looking at the
  /// same history. Left null the screen owns one, which is what the
  /// tests and the standalone route want.
  final CalculatorController? controller;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final _controller = widget.controller ?? CalculatorController();
  late final _feedback = FeedbackService(widget.settings);

  @override
  void dispose() {
    // Only dispose what this screen created; the shell owns the one it
    // passed in and will outlive this widget.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _openInput(InputMethod method) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Ways to enter maths')),
          body: InputMethodsScreen(initial: method),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return HardwareKeyboardInput(
          controller: _controller,
          onKey: _feedback.onKeyPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.m,
              Space.s,
              Space.m,
              Space.m,
            ),
            child: Column(
              children: [
                _Toolbar(controller: _controller, palette: palette),
                const SizedBox(height: Space.s),
                CalculatorDisplay(controller: _controller),
                const SizedBox(height: Space.m),
                _InputMethodStrip(onOpen: _openInput),
                const SizedBox(height: Space.m),
                Expanded(
                  child: AnimatedBuilder(
                    animation: widget.settings,
                    builder: (context, _) => Keypad(
                      controller: _controller,
                      layoutStyle: widget.settings.layoutStyle,
                      feedback: _feedback,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Clear, the angle mode, and nothing else.
///
/// Above the display rather than on the keypad, because these two say
/// what state the calculator is in rather than doing arithmetic — and
/// because a keypad that has to carry its own settings is a keypad two
/// keys short of a digit.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller, required this.palette});

  final CalculatorController controller;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolbarButton(
          label: 'Clear',
          icon: Icons.close_rounded,
          onTap: controller.clear,
          palette: palette,
        ),
        const Spacer(),
        _ToolbarButton(
          label: controller.angleMode.label,
          semanticLabel:
              'Angle mode: ${controller.angleMode.label}. '
              'Tap to change.',
          onTap: controller.toggleAngleMode,
          palette: palette,
          emphasised: true,
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onTap,
    required this.palette,
    this.icon,
    this.semanticLabel,
    this.emphasised = false,
  });

  final String label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final Palette palette;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasised
        ? palette.accentOnSurface
        : palette.secondaryLabel;

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: TouchTarget.minimum,
                minWidth: TouchTarget.minimum,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Space.m),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppType.footnote.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Touch · Keyboard · Voice · Camera, under the display.
class _InputMethodStrip extends StatelessWidget {
  const _InputMethodStrip({required this.onOpen});

  final void Function(InputMethod) onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // Touch is where you already are, so it is shown as the current
          // method rather than as something to tap.
          Expanded(
            child: _Method(
              label: 'Touch',
              icon: Icons.touch_app_outlined,
              isCurrent: true,
              palette: palette,
              onTap: null,
            ),
          ),
          for (final method in InputMethod.values) ...[
            const SizedBox(width: Space.s),
            Expanded(
              child: _Method(
                label: method.label,
                icon: method.icon,
                isCurrent: false,
                palette: palette,
                onTap: () => onOpen(method),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({
    required this.label,
    required this.icon,
    required this.isCurrent,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isCurrent;
  final Palette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = isCurrent
        ? palette.accentSoft.background
        : palette.groupedBackground;
    final foreground = isCurrent
        ? palette.accentSoft.foreground
        : palette.secondaryLabel;

    return Semantics(
      button: onTap != null,
      selected: isCurrent,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(Radii.medium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.medium),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: AppType.caption1.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
