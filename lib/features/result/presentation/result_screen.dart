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

              // Show content progressively as it loads
              if (isLoading && result == null) ...[
                // Initial loading state
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
                        // Show data progressively with loading indicators for missing parts
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ResultInfoWidget(
                                  name: result.name.isNotEmpty
                                      ? result.name
                                      : "Memuat nama...",
                                  origin: result.origin.isNotEmpty
                                      ? result.origin
                                      : (result.name.isNotEmpty ? "Memuat asal..." : ""),
                                  description: result.description.isNotEmpty
                                      ? result.description
                                      : (result.name.isNotEmpty ? "Memuat deskripsi..." : ""),
                                  history: result.history.isNotEmpty
                                      ? result.history
                                      : (result.description.isNotEmpty ? "Memuat sejarah..." : ""),
                                  recipe: result.recipe,
                                ),
                                const SizedBox(height: 12),

                                // Show loading indicator for tags if name exists but tags are empty
                                if (result.tags.isNotEmpty)
                                  ResultTagsWidget(tags: result.tags)
                                else if (result.name.isNotEmpty && scanProvider.loading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: LinearProgressIndicator(),
                                  ),

                                const SizedBox(height: 12),
                                const ResultActionsWidget(),
                                const SizedBox(height: 20),

                                // Show related foods or loading indicator
                                if (result.relatedFoods.isNotEmpty)
                                  RelatedFoodsWidget(related: result.relatedFoods)
                                else if (result.description.isNotEmpty && scanProvider.loading)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      children: [
                                        Text("Memuat makanan serupa..."),
                                        SizedBox(height: 8),
                                        LinearProgressIndicator(),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 20),
                                // Show nearby restaurants that sell this food
                                NearbyRestaurantsSection(
                                  foodName: result.name,
                                  autoLoad: true,
                                ),
                              ],
                            ),

                            // Subtle loading overlay if still loading partial data
                            if (scanProvider.loading && result.name.isNotEmpty)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withAlpha(26), // 0.1 * 255 ≈ 26
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Memuat...",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
