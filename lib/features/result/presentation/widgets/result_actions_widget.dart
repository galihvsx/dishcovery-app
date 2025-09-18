import 'package:flutter/material.dart';

class ResultActionsWidget extends StatelessWidget {
  const ResultActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Save to collection
            },
            icon: const Icon(Icons.add),
            label: const Text("Save to Collection"),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Share
            },
            icon: const Icon(Icons.share),
            label: const Text("Share"),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
