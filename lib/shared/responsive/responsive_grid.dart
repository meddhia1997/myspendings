import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Lays cards out in 1 column on phones, more columns as width grows —
/// unlike GridView, each item keeps its own natural height instead of being
/// forced into a fixed aspect ratio.
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = gridColumnsFor(context);
        if (columns <= 1) {
          return Column(
            children: [
              for (final child in children)
                Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: child,
                ),
            ],
          );
        }

        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
