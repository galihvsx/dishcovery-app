import 'package:flutter/material.dart';

class RelatedFoodsWidget extends StatelessWidget {
  final List<String> related;

  const RelatedFoodsWidget({super.key, required this.related});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Related Foods / Where to Find",
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Column(
          children: related
              .map(
                (food) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(food),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Navigate ke detail makanan lain
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
