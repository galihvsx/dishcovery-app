import 'package:dishcovery_app/core/models/recipe_model.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/features/home/presentation/widgets/comments_bottom_sheet.dart';
import 'package:dishcovery_app/features/home/presentation/widgets/food_feed_card.dart';
import 'package:dishcovery_app/features/result/presentation/result_screen.dart';
import 'package:dishcovery_app/providers/feeds_provider.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DishcoveryHomePage extends StatefulWidget {
  const DishcoveryHomePage({super.key});

  static const String path = '/home';

  @override
  State<DishcoveryHomePage> createState() => _DishcoveryHomePageState();
}

class _DishcoveryHomePageState extends State<DishcoveryHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedsProvider>().loadInitialFeeds();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedsProvider>().loadMoreFeeds();
    }
  }

  void _navigateToDetail(FeedData feed) {
    final scanResult = _convertFeedToScan(feed);
    debugPrint('[DEBUG] DishcoveryHomePage: Navigating to ResultScreen');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(initialData: scanResult),
      ),
    ).then((_) {
      debugPrint(
        '[DEBUG] DishcoveryHomePage: Returned from ResultScreen - refreshing feeds',
      );
      // Refresh feeds when returning from result screen to show new scan data
      context.read<FeedsProvider>().refreshFeeds();
    });
  }

  Future<void> _handleSave(String feedId) async {
    final feedsProvider = context.read<FeedsProvider>();
    final historyProvider = context.read<HistoryProvider>();

    final index = feedsProvider.feeds.indexWhere((feed) => feed.id == feedId);
    if (index == -1) return;

    await feedsProvider.toggleSave(feedId);

    // Get updated feed state
    if (index >= feedsProvider.feeds.length) return;
    final updatedFeed = feedsProvider.feeds[index];
    final scan = _convertFeedToScan(updatedFeed);

    if (updatedFeed.isSaved) {
      await historyProvider.setFavoriteStatus(scan, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('collection_screen.added_message'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      await historyProvider.setFavoriteStatus(scan, false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('collection_screen.removed_message'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  ScanResult _convertFeedToScan(FeedData feed) {
    return ScanResult(
      firestoreId: feed.id,
      userId: feed.userId,
      userEmail: feed.userEmail,
      userName: feed.userName,
      isFood: true,
      imagePath: feed.imageUrl,
      imageUrl: feed.imageUrl,
      name: feed.name,
      origin: feed.origin,
      description: feed.description,
      history: feed.history,
      recipe: Recipe.fromJson(feed.recipe),
      tags: feed.tags,
      isPublic: true,
      createdAt: feed.createdAt,
      isFavorite: feed.isSaved,
    );
  }

  void _showCommentSheet(String feedId) {
    CommentsBottomSheet.show(context, feedId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<FeedsProvider>().refreshFeeds();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: colorScheme.surface,
              elevation: 0,
              floating: true,
              pinned: false,
              automaticallyImplyLeading: false,
              snap: true,
              title: Text(
                'Dishcovery',
                style: GoogleFonts.niconne(
                  fontSize: 32,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Consumer<FeedsProvider>(
              builder: (context, provider, child) {
                if (provider.feeds.isEmpty && provider.isLoading) {
                  // Initial loading state
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSkeletonCard(),
                      childCount: 3,
                    ),
                  );
                }

                if (provider.feeds.isEmpty && !provider.isLoading) {
                  // Empty state
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.no_meals_outlined,
                            size: 80,
                            color: colorScheme.onSurfaceVariant.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'home_screen.no_feeds_yet'.tr(),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'home_screen.start_scanning'.tr(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Feed list with infinite scroll
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < provider.feeds.length) {
                        final feed = provider.feeds[index];
                        return FoodFeedCard(
                          feed: feed,
                          onTap: () => _navigateToDetail(feed),
                          onLike: provider.toggleLike,
                          onSave: _handleSave,
                          onComment: _showCommentSheet,
                        );
                      } else if (provider.hasMore) {
                        // Loading more indicator
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                      } else {
                        // End of list
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'home_screen.all_feeds_viewed'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    childCount:
                        provider.feeds.length +
                        (provider.hasMore || provider.isLoading ? 1 : 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Skeletonizer(
      enabled: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Bone.square(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Bone.text(words: 2),
                  const SizedBox(height: 8),
                  const Bone.text(words: 1),
                  const SizedBox(height: 12),
                  const Bone.text(words: 10),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Bone.icon(),
                      const SizedBox(width: 8),
                      const Bone.text(width: 30),
                      const SizedBox(width: 16),
                      const Bone.icon(),
                      const SizedBox(width: 8),
                      const Bone.text(width: 30),
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
