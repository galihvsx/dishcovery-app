import 'package:flutter/material.dart';

class ResultTagsWidget extends StatelessWidget {
  final List<String> tags;

  const ResultTagsWidget({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag),
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.2),
              labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          )
          .toList(),
    );
  }
}
