import 'package:flutter/material.dart';

class ResultInfoWidget extends StatelessWidget {
  final String name;
  final String origin;
  final String description;

  const ResultInfoWidget({
    super.key,
    required this.name,
    required this.origin,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(origin, style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        Text(description, style: textTheme.bodyMedium),
      ],
    );
  }
}
