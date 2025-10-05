import 'package:dishcovery_app/features/result/presentation/widgets/not_food_widget.dart';
import 'package:dishcovery_app/features/result/presentation/widgets/related_foods_widget.dart';
import 'package:dishcovery_app/features/result/presentation/widgets/result_actions_widget.dart';
import 'package:dishcovery_app/features/result/presentation/widgets/result_image_widget.dart';
import 'package:dishcovery_app/features/result/presentation/widgets/result_info_widget.dart';
import 'package:dishcovery_app/features/result/presentation/widgets/result_tags_widget.dart';
import 'package:dishcovery_app/features/result/widgets/nearby_restaurants_section.dart';
import 'package:dishcovery_app/providers/scan_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final bool fromHistory;

  const ResultScreen({
    super.key,
    required this.imagePath,
    this.fromHistory = false,
  });

  static const String path = '/result';

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _translated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().processImage(widget.imagePath);
    });
  }

  void _toggleTranslate() {
    setState(() => _translated = !_translated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _translated
              ? "Hasil diterjemahkan ke English 🇬🇧 (coming soon)"
              : "Kembali ke Bahasa Indonesia 🇮🇩",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();
    final isLoading = scanProvider.loading;
    final result = scanProvider.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Result"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: _toggleTranslate,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResultImageWidget(imagePath: widget.imagePath),
              const SizedBox(height: 16),

              if (isLoading) ...[
                // Show custom loading UI instead of skeletonizer
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        scanProvider.loadingMessage,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Mohon tunggu sebentar...",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (scanProvider.error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Error: ${scanProvider.error}",
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (result == null)
                      const Center(child: Text("Tidak ada hasil"))
                    else ...[
                      if (result.isFood == false) ...[
                        const NotFoodWidget(),
                      ] else ...[
                        ResultInfoWidget(
                          name: result.name,
                          origin: result.origin,
                          description: result.description,
                          history: result.history,
                          recipe: result.recipe,
                        ),
                        const SizedBox(height: 12),
                        if (result.tags.isNotEmpty)
                          ResultTagsWidget(tags: result.tags),
                        const SizedBox(height: 12),
                        const ResultActionsWidget(),
                        const SizedBox(height: 20),
                        if (result.relatedFoods.isNotEmpty)
                          RelatedFoodsWidget(related: result.relatedFoods),
                        const SizedBox(height: 20),
                        // Show nearby restaurants that sell this food
                        NearbyRestaurantsSection(
                          foodName: result.name,
                          autoLoad: true,
                        ),
                      ],
                    ],
                  ],
                ),
              ],

              if (widget.fromHistory)
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    "Dibuka dari History",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
