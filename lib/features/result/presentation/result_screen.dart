import 'dart:io';

import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:dishcovery_app/features/result/presentation/widgets/not_food_widget.dart';
import 'package:dishcovery_app/features/result/widgets/nearby_restaurants_section.dart';
import 'package:dishcovery_app/providers/feeds_provider.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:dishcovery_app/providers/scan_provider.dart';
import 'package:easy_localization/easy_localization.dart';
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
  bool _isSaved = false;
  bool _hasProcessedImage = false; // Guard to prevent duplicate processing
  bool _isTogglingCollection = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // PROCESS GUARD: Prevent multiple processImage calls on widget rebuild
      if (_hasProcessedImage) {
        debugPrint(
          "ResultScreen: Image already processed, skipping duplicate call",
        );
        return;
      }

      _hasProcessedImage = true;
      final scanProvider = context.read<ScanProvider>();
      scanProvider.clear();

      if (widget.initialData != null) {
        scanProvider.setResult(widget.initialData!);
        _isSaved = true;
      } else {
        scanProvider.processImage(widget.imagePath!, context: context);
      }
    });
  }

  ScanResult? _currentResult(
    ScanProvider scanProvider,
    HistoryProvider historyProvider,
  ) {
    final base = scanProvider.result ?? widget.initialData;
    if (base == null) return null;
    if (historyProvider.isInCollection(base))
      return base.copyWith(isFavorite: true);
    return base;
  }

  Future<void> _toggleCollection(
    ScanProvider scanProvider,
    HistoryProvider historyProvider,
  ) async {
    if (!_isSaved || _isTogglingCollection) return;

    final activeResult = _currentResult(scanProvider, historyProvider);
    if (activeResult == null) return;

    setState(() => _isTogglingCollection = true);

    final currentlyCollected = historyProvider.isInCollection(activeResult);
    await historyProvider.setFavoriteStatus(activeResult, !currentlyCollected);
    final firestoreId = activeResult.firestoreId;
    if (firestoreId != null) {
      await FirestoreService().setSavedStatus(
        firestoreId,
        !currentlyCollected,
      );
      try {
        final feedsProvider = context.read<FeedsProvider>();
        feedsProvider.updateSavedStatus(firestoreId, !currentlyCollected);
      } catch (_) {
        // Feeds provider not available in this context
      }
    }

    if (!mounted) return;

    setState(() => _isTogglingCollection = false);
    final message = !currentlyCollected
        ? 'result_screen.saved_to_collection'.tr()
        : 'result_screen.removed_from_collection'.tr();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _shareResult() {
    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('result_screen.sharing_result'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final isLoading = scanProvider.loading;
    final result = scanProvider.result;
    final activeResult = _currentResult(scanProvider, historyProvider);
    final isCollected = historyProvider.isInCollection(activeResult);

    // Determine image source: prefer imageUrl for Firebase data, fall back to local path
    final String? imageUrl = (widget.initialData?.imageUrl ?? '').isNotEmpty
        ? widget.initialData!.imageUrl
        : (result?.imageUrl ?? '').isNotEmpty
        ? result!.imageUrl
        : null;
    final String? localImagePath =
        widget.initialData?.imagePath ?? widget.imagePath;

    // Check if result is saved (either local id or firestoreId)
    if (result != null &&
        (result.id != null || result.firestoreId != null) &&
        !_isSaved) {
      _isSaved = true;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('result_screen.title'.tr()),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full width image section
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildImageWidget(imageUrl, localImagePath, context),
                ),
                const SizedBox(height: 16),

                Padding(
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'result_screen.error_prefix'.tr(
                                    args: [scanProvider.error!],
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!isLoading && result == null)
                        Center(child: Text('result_screen.no_result'.tr()))
                      else if (result != null && result.isFood == false)
                        const NotFoodWidget()
                      else
                        Skeletonizer(
                          enabled: isLoading && result == null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result?.name ??
                                    'result_screen.loading_name'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    result?.origin ??
                                        'result_screen.loading_origin'.tr(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Action buttons
                              Row(
                                children: [
                                  _buildActionButton(
                                    context,
                                    icon: isCollected
                                        ? Icons.bookmark
                                        : Icons.bookmark_outline,
                                    isEnabled:
                                        _isSaved && !_isTogglingCollection,
                                    isActive: isCollected,
                                    onTap: () {
                                      _toggleCollection(
                                        scanProvider,
                                        historyProvider,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    context,
                                    icon: Icons.share_outlined,
                                    isEnabled: _isSaved,
                                    isActive: false,
                                    onTap: _shareResult,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              _buildSection(
                                context,
                                icon: Icons.description_outlined,
                                title: 'result_screen.description'.tr(),
                                content:
                                    result?.description ??
                                    'result_screen.loading_desc'.tr() * 5,
                              ),

                              if (result?.history != null &&
                                  result!.history.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildSection(
                                  context,
                                  icon: Icons.history,
                                  title: 'result_screen.history'.tr(),
                                  content: result.history,
                                ),
                              ],

                              if (result?.recipe != null) ...[
                                if (result!.recipe.ingredients.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _buildListSection(
                                    context,
                                    icon: Icons.kitchen_outlined,
                                    title: 'result_screen.ingredients'.tr(),
                                    items: result.recipe.ingredients,
                                  ),
                                ],
                                if (result.recipe.steps.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _buildListSection(
                                    context,
                                    icon: Icons.restaurant_menu_outlined,
                                    title: 'result_screen.steps'.tr(),
                                    items: result.recipe.steps,
                                    isNumbered: true,
                                  ),
                                ],
                              ],

                              if (result?.tags != null &&
                                  result!.tags.isNotEmpty) ...[
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(
    String? imageUrl,
    String? localPath,
    BuildContext context,
  ) {
    // First try to use network image if URL is available
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // If network image fails, try local file
          if (localPath != null && File(localPath).existsSync()) {
            return Image.file(File(localPath), fit: BoxFit.cover);
          }
          return _buildImageErrorWidget(context);
        },
      );
    }

    // If no URL, try local file
    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }

    // Show error widget if no image can be displayed
    return _buildImageErrorWidget(context);
  }

  Widget _buildImageErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required bool isEnabled,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? (isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 20,
              color: isEnabled
                  ? (isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface)
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeletonizer(
          enabled: false,
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
    required IconData icon,
    required String title,
    required List<String> items,
    bool isNumbered = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeletonizer(
          enabled: false,
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
}
