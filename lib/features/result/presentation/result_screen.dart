import 'dart:io';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/features/result/presentation/widgets/not_food_widget.dart';
import 'package:dishcovery_app/features/result/widgets/nearby_restaurants_section.dart';
import 'package:dishcovery_app/providers/scan_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ResultScreen extends StatefulWidget {
  final String? imagePath;
  final ScanResult? initialData;

  const ResultScreen({super.key, this.imagePath, this.initialData})
      : assert(imagePath != null || initialData != null);

  static const String path = '/result';

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _translated = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    final scanProvider = context.read<ScanProvider>();

    scanProvider.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialData != null) {
        // If from history, directly show data
        scanProvider.setResult(widget.initialData!);
        _isSaved = true; // Already in database
      } else {
        // If from new scan, call API
        scanProvider.processImage(widget.imagePath!, context: context);
      }
    });
  }

  void _toggleTranslate() {
    if (_isSaved) {
      setState(() => _translated = !_translated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translated
                ? "Hasil diterjemahkan ke English 🇬🇧"
                : "Kembali ke Bahasa Indonesia 🇮🇩",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveToCollection() {
    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Disimpan ke koleksi"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareResult() {
    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Membagikan hasil..."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();
    final isLoading = scanProvider.loading;
    final result = scanProvider.result;
    final displayImagePath = widget.initialData?.imagePath ?? widget.imagePath!;

    // Update saved status when result is available
    if (result != null && result.id != null && !_isSaved) {
      _isSaved = true;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Hasil Scan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (File(displayImagePath).existsSync())
                    Image.file(
                      File(displayImagePath),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error handling
                  if (scanProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 24,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Error: ${scanProvider.error}",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!isLoading && result == null)
                    const Center(child: Text("Tidak ada hasil"))
                  else if (result != null && result.isFood == false)
                    const NotFoodWidget()
                  else
                    // Main content with skeleton loading
                    Skeletonizer(
                      enabled: isLoading && result == null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Food name
                          Text(
                            result?.name ?? "Nama Makanan Loading",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),

                          // Origin
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                result?.origin ?? "Asal Daerah Loading",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Action buttons (icon only)
                          Row(
                            children: [
                              // Save to collection
                              Container(
                                decoration: BoxDecoration(
                                  color: _isSaved
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _isSaved ? _saveToCollection : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.bookmark_outline,
                                        size: 20,
                                        color: _isSaved
                                            ? Theme.of(context).colorScheme.onPrimaryContainer
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Translate
                              Container(
                                decoration: BoxDecoration(
                                  color: _isSaved
                                      ? (_translated
                                          ? Theme.of(context).colorScheme.primaryContainer
                                          : Theme.of(context).colorScheme.surfaceContainerHighest)
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _isSaved ? _toggleTranslate : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.translate,
                                        size: 20,
                                        color: _isSaved
                                            ? (_translated
                                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                                : Theme.of(context).colorScheme.onSurface)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Share
                              Container(
                                decoration: BoxDecoration(
                                  color: _isSaved
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _isSaved ? _shareResult : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.share_outlined,
                                        size: 20,
                                        color: _isSaved
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Description Section
                          _buildSection(
                            context,
                            icon: 'solar:document-text-bold-duotone',
                            title: 'Deskripsi',
                            content: result?.description ??
                                "Ini adalah deskripsi makanan yang sedang dimuat. " * 5,
                            isLoading: isLoading && result == null,
                          ),

                          // History Section
                          if (result?.history != null && result!.history.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSection(
                              context,
                              icon: 'solar:history-3-bold-duotone',
                              title: 'Sejarah',
                              content: result.history,
                              isLoading: false,
                            ),
                          ],

                          // Recipe Section
                          if (result?.recipe != null) ...[
                            // Ingredients
                            if (result!.recipe.ingredients.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildListSection(
                                context,
                                icon: 'solar:bottle-bold-duotone',
                                title: 'Bahan-bahan',
                                items: result.recipe.ingredients,
                                isLoading: false,
                              ),
                            ],

                            // Steps
                            if (result.recipe.steps.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildListSection(
                                context,
                                icon: 'solar:chef-hat-bold-duotone',
                                title: 'Langkah-Langkah',
                                items: result.recipe.steps,
                                isNumbered: true,
                                isLoading: false,
                              ),
                            ],
                          ],

                          // Tags
                          if (result?.tags != null && result!.tags.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: result.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // Nearby Restaurants
                          if (result != null && result.isFood) ...[
                            const SizedBox(height: 24),
                            NearbyRestaurantsSection(
                              foodName: result.name,
                              autoLoad: true,
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String icon,
    required String title,
    required String content,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (not affected by skeleton)
        Skeletonizer(
          enabled: false,
          child: Row(
            children: [
              Icon(
                _getIconData(icon),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Content (affected by skeleton)
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildListSection(
    BuildContext context, {
    required String icon,
    required String title,
    required List<String> items,
    bool isNumbered = false,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (not affected by skeleton)
        Skeletonizer(
          enabled: false,
          child: Row(
            children: [
              Icon(
                _getIconData(icon),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // List items (affected by skeleton)
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isNumbered ? '${index + 1}' : '•',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'solar:document-text-bold-duotone':
        return Icons.description_outlined;
      case 'solar:history-3-bold-duotone':
        return Icons.history;
      case 'solar:bottle-bold-duotone':
        return Icons.kitchen_outlined;
      case 'solar:chef-hat-bold-duotone':
        return Icons.restaurant_menu_outlined;
      default:
        return Icons.info_outline;
    }
  }
}