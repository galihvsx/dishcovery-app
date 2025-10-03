// lib/features/result/presentation/widgets/result_info_widget.dart

import 'package:dishcovery_app/core/models/recipe_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ResultInfoWidget extends StatelessWidget {
  final String name;
  final String origin;
  final String description;
  final String history;
  final Recipe recipe;

  const ResultInfoWidget({
    super.key,
    required this.name,
    required this.origin,
    required this.description,
    required this.history,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    final ingredientsMarkdown = recipe.ingredients
        .map((e) => '- $e')
        .join('\n');
    final stepsMarkdown = recipe.steps
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          origin,
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        Text("Deskripsi", style: titleStyle),
        const SizedBox(height: 4),
        MarkdownBody(data: description, selectable: true),
        const SizedBox(height: 16),

        Text("Sejarah", style: titleStyle),
        const SizedBox(height: 4),
        MarkdownBody(data: history, selectable: true),
        const SizedBox(height: 16),

        if (recipe.ingredients.isNotEmpty) ...[
          Text("Bahan-bahan", style: titleStyle),
          const SizedBox(height: 4),
          MarkdownBody(data: ingredientsMarkdown, selectable: true),
          const SizedBox(height: 16),
        ],

        if (recipe.steps.isNotEmpty) ...[
          Text("Langkah-langkah", style: titleStyle),
          const SizedBox(height: 4),
          MarkdownBody(data: stepsMarkdown, selectable: true),
        ],
      ],
    );
  }
}
