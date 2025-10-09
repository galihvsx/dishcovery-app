import 'package:dishcovery_app/core/models/recipe_model.dart';
import 'package:easy_localization/easy_localization.dart';
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

  Widget _buildSection(
    BuildContext context,
    {
    required IconData icon,
    required String title,
    required String content,
  } ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: content,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final ingredientsMarkdown = recipe.ingredients.isNotEmpty
        ? recipe.ingredients.map((e) => '- $e').join('\n')
        : '';
    final stepsMarkdown = recipe.steps.isNotEmpty
        ? recipe.steps
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value}')
            .join('\n')
        : '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Makanan
          Text(
            name,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                origin,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section Deskripsi
          _buildSection(
            context,
            icon: Icons.restaurant_menu_rounded,
            title: "result_screen.description".tr(),
            content: description,
          ),

          // Section Sejarah
          _buildSection(
            context,
            icon: Icons.history_edu_rounded,
            title: "result_screen.history".tr(),
            content: history,
          ),

          // Section Bahan
          if (ingredientsMarkdown.isNotEmpty)
            _buildSection(
              context,
              icon: Icons.shopping_basket_rounded,
              title: "result_screen.ingredients".tr(),
              content: ingredientsMarkdown,
            ),

          // Section Langkah
          if (stepsMarkdown.isNotEmpty)
            _buildSection(
              context,
              icon: Icons.format_list_numbered_rounded,
              title: "result_screen.steps".tr(),
              content: stepsMarkdown,
            ),
        ],
      ),
    );
  }
}