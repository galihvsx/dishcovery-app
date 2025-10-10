import 'dart:io';
import 'dart:ui';

import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/widgets/custom_app_bar.dart';
import 'package:dishcovery_app/core/widgets/theme_switcher.dart';
import 'package:dishcovery_app/features/result/presentation/result_screen.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  static const String path = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isInitialized = false;
  bool _isResumingFromBackground = false;
  DateTime? _lastRefreshTime;
  bool _isRefreshing = false;

  Future<void> _refreshHistory(BuildContext context, {bool force = false}) async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Haptic feedback for better UX
    HapticFeedback.lightImpact();

    final provider = Provider.of<HistoryProvider>(context, listen: false);

    try {
      // Force refresh by clearing caches first
      // This ensures we get fresh data but still prevents duplicates
      await provider.loadHistory();

      // Update last refresh time
      _lastRefreshTime = DateTime.now();

      // Show success feedback
      if (mounted) {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  provider.historyList.isEmpty
                      ? 'history_screen.refresh_no_data'.tr()
                      : 'history_screen.refresh_success'.tr(
                          args: [provider.historyList.length.toString()],
                        ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('history_screen.refresh_error'.tr()),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Only load history if not already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHistoryIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we're returning from another screen
    if (!_isResumingFromBackground) {
      _isResumingFromBackground = true;
      // Use a delayed callback to avoid triggering during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only refresh if it's been more than 2 seconds since last load
        // This prevents unnecessary refreshes when quickly navigating
        _initializeHistoryIfNeeded();
      });
    }
  }

  void _initializeHistoryIfNeeded() {
    if (_isInitialized) return;

    final provider = Provider.of<HistoryProvider>(context, listen: false);

    // Only load if the list is empty and not currently loading
    if (provider.historyList.isEmpty && !provider.isLoading) {
      provider.loadHistory();
    }

    _isInitialized = true;
  }

  /// Format the last refresh time
  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'history_screen.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return 'history_screen.minutes_ago'.tr(args: [difference.inMinutes.toString()]);
    } else if (difference.inHours < 24) {
      return 'history_screen.hours_ago'.tr(args: [difference.inHours.toString()]);
    } else {
      return DateFormat('dd MMM HH:mm').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'history_screen.title'.tr(),
        actions: [
          // Refresh button in app bar
          Consumer<HistoryProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: _isRefreshing ? null : () => _refreshHistory(context, force: true),
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'history_screen.refresh_tooltip'.tr(),
              );
            },
          ),
          const ThemeSwitcher(),
        ],
      ),
      body: RefreshIndicator(
        displacement: 40,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        strokeWidth: 3,
        onRefresh: () => _refreshHistory(context),
        child: Consumer<HistoryProvider>(
          builder: (context, provider, child) {
            final history = provider.historyList;

            if (history.isEmpty && !provider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'history_screen.empty_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'history_screen.empty_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'history_screen.pull_to_refresh_hint'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show loading skeleton when refreshing
            if (provider.isLoading && history.isNotEmpty) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length > 5 ? 5 : history.length,
                itemBuilder: (context, index) {
                  return Container(
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  );
                },
              );
            }

            return CustomScrollView(
              slivers: [
                // Header with item count and last refresh info
                if (history.isNotEmpty || _lastRefreshTime != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            history.isNotEmpty
                                ? 'history_screen.item_count'.tr(args: [history.length.toString()])
                                : 'history_screen.no_items'.tr(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_lastRefreshTime != null)
                            Text(
                              'history_screen.last_updated'.tr(
                                args: [_formatRefreshTime(_lastRefreshTime!)],
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // Main content
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ScanResult item = history[index];
                      final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

                      Widget buildErrorPlaceholder() {
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      Widget buildEmptyPlaceholder() {
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultScreen(initialData: item),
                            ),
                          );
                        },
                        child: Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background image
                                if (item.imagePath.isNotEmpty && File(item.imagePath).existsSync())
                                  Image.file(
                                    File(item.imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return buildErrorPlaceholder();
                                    },
                                  )
                                else if (item.imageUrl.isNotEmpty)
                                  Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return buildEmptyPlaceholder();
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return buildErrorPlaceholder();
                                    },
                                  )
                                else
                                  buildEmptyPlaceholder(),

                                // Gradient overlay
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black26,
                                        Colors.black87,
                                      ],
                                      stops: [0.3, 0.6, 1.0],
                                    ),
                                  ),
                                ),

                                // Content overlay with backdrop blur
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: Colors.black26,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              item.name.isNotEmpty
                                                  ? item.name
                                                  : 'history_screen.unknown_dish'.tr(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.origin.isNotEmpty
                                                      ? item.origin
                                                      : 'history_screen.unknown_origin'.tr(),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  dateFormatter.format(item.createdAt),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Delete button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('history_screen.delete_dialog_title'.tr()),
                                            content: Text('history_screen.delete_dialog_content'.tr()),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text('common.cancel'.tr()),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await provider.deleteHistory(item);
                                                  if (!mounted) return;
                                                  Navigator.pop(context);
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('history_screen.snackbar_deleted'.tr()),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'common.delete'.tr(),
                                                  style: const TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: history.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}