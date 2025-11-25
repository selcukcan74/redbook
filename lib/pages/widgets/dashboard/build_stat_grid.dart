import 'package:flutter/material.dart';

class BuildStatGrid extends StatelessWidget {
  final List<Widget> children;

  const BuildStatGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int count = width >= 1400
            ? 4
            : width >= 1000
            ? 3
            : width >= 700
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            mainAxisExtent: 160,
          ),
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}
