import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Galaxy S25 CSS / Flutter logical size: 6.2" FHD+ 1080×2340 at ~19.5:9.
/// Chrome device-mode and this frame both use 412×915 logical pixels
/// (1080/2.625 ≈ 411, 2340/2.625 ≈ 891–915 depending on system UI).
const kS25LogicalSize = Size(412, 915);

/// On a wide desktop window, render the app inside an S25-sized phone
/// frame so layout matches a real handset. On a phone-sized window the
/// child fills the screen.
///
/// Important: do **not** wrap the phone in [FittedBox] / [Transform]. Flutter
/// web mouse hit-testing through those transforms was dropping taps on the
/// geometry canvas (buttons still worked; the empty drawing area did not).
/// We layout the frame at a real pixel size instead.
class AdaptivePhoneShell extends StatelessWidget {
  const AdaptivePhoneShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useFrame = constraints.maxWidth >= 520 && constraints.maxHeight >= 640;
        if (!useFrame) return child;

        const headerH = 28.0;
        final availW = constraints.maxWidth;
        final availH = math.max(0.0, constraints.maxHeight - headerH);
        final scale = math.min(
          1.0,
          math.min(availW / kS25LogicalSize.width, availH / kS25LogicalSize.height),
        );
        final phoneW = kS25LogicalSize.width * scale;
        final phoneH = kS25LogicalSize.height * scale;

        return ColoredBox(
          color: const Color(0xFF0A0A0A),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Phone preview · Galaxy S25 (412×915)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: phoneW,
                    height: phoneH,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(36 * scale.clamp(0.5, 1.0)),
                      border: Border.all(
                        color: const Color(0xFF444444),
                        width: math.max(6.0, 10 * scale),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 4),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(phoneW, phoneH),
                        padding: EdgeInsets.only(top: 12 * scale, bottom: 16 * scale),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
