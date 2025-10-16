import 'package:dishcovery_app/core/models/comment_model.dart';
import 'package:dishcovery_app/providers/comment_provider.dart';
import 'package:dishcovery_app/providers/feeds_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Comments Bottom Sheet Widget
///
/// A modal bottom sheet that displays comments for a feed item with:
/// - Real-time comment updates
/// - Add/delete comment functionality
/// - Pull-to-refresh
/// - Empty, loading, and error states
/// - Auto-scroll to bottom when new comment added
class CommentsBottomSheet extends StatefulWidget {
  final String feedId;

  const CommentsBottomSheet({super.key, required this.feedId});

  /// Static method to show the bottom sheet
  static Future<void> show(BuildContext context, String feedId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(feedId: feedId),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    // Load comments when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CommentProvider>(context, listen: false);
      provider.loadComments(widget.feedId);
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _textController.text.trim().isNotEmpty;
    });
  }

  Future<void> _handleSubmitComment(CommentProvider provider) async {
    if (!_isComposing) return;

    final content = _textController.text.trim();
    if (content.isEmpty) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Submit comment
    final success = await provider.addComment(widget.feedId, content);

    if (success) {
      _updateFeedCommentCount(increase: true);

      // Clear text field
      _textController.clear();
      setState(() {
        _isComposing = false;
      });

      // Scroll to bottom after a short delay to allow new comment to render
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Success haptic
      HapticFeedback.mediumImpact();
    } else {
      // Error haptic
      HapticFeedback.heavyImpact();

      // Show error snackbar
      if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteComment(
    CommentProvider provider,
    Comment comment,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final success = await provider.deleteComment(comment.id, widget.feedId);

      if (success) {
        _updateFeedCommentCount(increase: false);
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
        if (mounted && provider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRefresh(CommentProvider provider) async {
    HapticFeedback.lightImpact();
    await provider.loadComments(widget.feedId);
  }

  void _updateFeedCommentCount({required bool increase}) {
    try {
      final feedsProvider = Provider.of<FeedsProvider>(context, listen: false);
      if (increase) {
        feedsProvider.incrementCommentCount(widget.feedId);
      } else {
        feedsProvider.decrementCommentCount(widget.feedId);
      }
    } on ProviderNotFoundException {
      // Feed provider not available in this context
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Draggable handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(theme, colorScheme),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child: Consumer<CommentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.comments.isEmpty) {
                  return _buildLoadingState(colorScheme);
                }

                if (provider.error != null && provider.comments.isEmpty) {
                  return _buildErrorState(theme, colorScheme, provider);
                }

                if (provider.comments.isEmpty) {
                  return _buildEmptyState(theme, colorScheme);
                }

                return _buildCommentsList(provider);
              },
            ),
          ),

          // Input section
          _buildInputSection(theme, colorScheme, keyboardHeight),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Consumer<CommentProvider>(
      builder: (context, provider, _) {
        final count = provider.commentCount;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Comments',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading comments...',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme colorScheme,
    CommentProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load comments',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'An unknown error occurred',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _handleRefresh(provider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(CommentProvider provider) {
    return RefreshIndicator(
      onRefresh: () => _handleRefresh(provider),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.comments.length,
        itemBuilder: (context, index) {
          final comment = provider.comments[index];
          return _buildCommentItem(comment, provider);
        },
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, CommentProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = provider.currentUser?.uid;
    final isOwner = currentUserId == comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: comment.userPhotoUrl != null
                ? NetworkImage(comment.userPhotoUrl!)
                : null,
            child: comment.userPhotoUrl == null
                ? Icon(
                    Icons.account_circle,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Username
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Timestamp
                    Text(
                      timeago.format(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Comment text
                Text(comment.content, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),

          // Delete button (only for comment owner)
          if (isOwner) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _handleDeleteComment(provider, comment),
              color: colorScheme.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection(
    ThemeData theme,
    ColorScheme colorScheme,
    double keyboardHeight,
  ) {
    return Consumer<CommentProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: keyboardHeight > 0
                ? 8
                : MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text field
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              IconButton(
                icon: provider.isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: _isComposing
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                      ),
                onPressed: _isComposing && !provider.isSubmitting
                    ? () => _handleSubmitComment(provider)
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: _isComposing
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
