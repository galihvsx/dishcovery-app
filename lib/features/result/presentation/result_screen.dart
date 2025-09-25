import 'package:flutter/material.dart';
import 'widgets/result_image_widget.dart';
import 'widgets/result_info_widget.dart';
import 'widgets/result_tags_widget.dart';
import 'widgets/result_actions_widget.dart';
import 'widgets/related_foods_widget.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final bool fromHistory;

  const ResultScreen({
    super.key, 
    required this.imagePath,
    this.fromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Result"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResultImageWidget(imagePath: imagePath),
            const SizedBox(height: 16),
            const ResultInfoWidget(
              name: "Nasi Uduk",
              origin: "Jakarta, Indonesia",
              description:
                  "Nasi uduk adalah hidangan nasi gurih yang dimasak dengan santan, populer sebagai sarapan di Jakarta.",
            ),
            const SizedBox(height: 12),
            const ResultTagsWidget(tags: ["Ayam", "Santan", "Nasi Putih"]),
            const SizedBox(height: 12),
            const ResultActionsWidget(),
            const SizedBox(height: 20),
            const RelatedFoodsWidget(
              related: ["Nasi Kuning", "Nasi Ulam", "Nasi Liwet"],
            ),
          ],
        ),
      ),
    );
  }
}
