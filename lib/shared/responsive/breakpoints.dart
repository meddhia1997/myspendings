import 'package:flutter/material.dart';

/// Width breakpoints the app adapts around. Values follow Material's
/// compact/medium/expanded window size classes.
class Breakpoints {
  Breakpoints._();

  static const double compact = 600; // phones, portrait
  static const double medium = 840; // large phones landscape, small tablets
  static const double expanded = 1200; // tablets, foldables, desktop
}

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.medium) return ScreenSize.expanded;
  if (width >= Breakpoints.compact) return ScreenSize.medium;
  return ScreenSize.compact;
}

bool isCompact(BuildContext context) =>
    screenSizeOf(context) == ScreenSize.compact;

/// How many columns a card grid should use at the current width.
int gridColumnsFor(BuildContext context) {
  switch (screenSizeOf(context)) {
    case ScreenSize.compact:
      return 1;
    case ScreenSize.medium:
      return 2;
    case ScreenSize.expanded:
      return 3;
  }
}

/// Caps content width on large screens and centers it, so cards/text don't
/// stretch edge-to-edge on tablets or landscape.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
