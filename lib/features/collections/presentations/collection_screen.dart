import 'dart:io';

import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:dishcovery_app/core/widgets/custom_app_bar.dart';
import 'package:dishcovery_app/features/result/presentation/result_screen.dart';
import 'package:dishcovery_app/providers/feeds_provider.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  static const String path = '/collections';

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HistoryProvider>().loadFavorites();
    });
  }

  Future<void> _refreshCollections(BuildContext context) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await context.read<HistoryProvider>().loadFavorites();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'collection_screen.title'.tr()),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favoritesList;

          if (favorites.isEmpty) {
            return _CollectionEmptyState(
              onRefresh: () => _refreshCollections(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshCollections(context),
            displacement: 40,
            color: Theme.of(context).colorScheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = favorites[index];
                return _CollectionCard(
                  scan: item,
                  onOpen: () => _openResult(context, item),
                  onRemove: () => _removeFromCollection(context, item),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemCount: favorites.length,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openResult(BuildContext context, ScanResult scan) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ResultScreen(initialData: scan)));
  }

  Future<void> _removeFromCollection(
    BuildContext context,
    ScanResult scan,
  ) async {
    final historyProvider = context.read<HistoryProvider>();
    final feedsProvider = context.read<FeedsProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await historyProvider.setFavoriteStatus(scan, false);

    final feedId = scan.firestoreId;
    if (feedId != null) {
      await FirestoreService().setSavedStatus(feedId, false);
      feedsProvider.updateSavedStatus(feedId, false);
    }
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('collection_screen.removed_message'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _CollectionCard({
    required this.scan,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CollectionImage(scan: scan),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          scan.origin,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  if (scan.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          scan.tags
                              .take(4)
                              .map(
                                (tag) => Chip(
                                  label: Text('#$tag'),
                                  backgroundColor: colorScheme.primaryContainer
                                      .withAlpha(64),
                                  labelStyle: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.open_in_new),
                        label: Text('collection_screen.view_detail'.tr()),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.bookmark_remove_outlined),
                        tooltip: 'collection_screen.remove_tooltip'.tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionImage extends StatelessWidget {
  final ScanResult scan;

  const _CollectionImage({required this.scan});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
    );

    if (scan.imageUrl.isNotEmpty) {
      return Image.network(
        scan.imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    if (scan.imagePath.isNotEmpty) {
      final file = File(scan.imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      }
    }

    return placeholder;
  }
}

class _CollectionEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CollectionEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 40,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'collection_screen.empty_title'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'collection_screen.empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
