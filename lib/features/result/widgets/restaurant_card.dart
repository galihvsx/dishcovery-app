import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dishcovery_app/core/models/place_model.dart';

class RestaurantCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback? onTap;

  const RestaurantCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Extract city from address components
    String? city = _extractCity();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            _buildImageSection(colorScheme),

            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant name
                    Text(
                      place.displayName?.text ??
                          'result_screen.unknown_restaurant_name'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating and price level
                    if (place.rating != null || place.priceLevel != null)
                      _buildRatingAndPrice(theme, colorScheme),

                    const SizedBox(height: 4),

                    // Address
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.formattedAddress ??
                                place.shortFormattedAddress ??
                                'result_screen.no_address'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (city != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_city,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  city,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Navigate button
                    const SizedBox(height: 8),
                    _buildNavigateButton(context, theme, colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ColorScheme colorScheme) {
    // Check if place has photos
    final hasPhoto = place.photos != null && place.photos!.isNotEmpty;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: hasPhoto
          ? _buildPhotoWidget(place.photos!.first)
          : _buildPlaceholderImage(colorScheme),
    );
  }

  Widget _buildPhotoWidget(Photo photo) {
    // For now, we'll use a placeholder since we need to implement photo fetching
    // In production, you would use the photo reference to fetch from Google Places Photos API
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder for actual image
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade300, Colors.grey.shade400],
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.restaurant, size: 40, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.restaurant_menu,
        size: 48,
        color: colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildRatingAndPrice(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        if (place.rating != null) ...[
          Icon(Icons.star, size: 16, color: Colors.amber.shade600),
          const SizedBox(width: 4),
          Text(
            place.rating!.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (place.userRatingCount != null) ...[
            Text(
              ' (${place.userRatingCount})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
        if (place.rating != null && place.priceLevel != null)
          const SizedBox(width: 12),
        if (place.priceLevel != null) ...[
          Text(
            _getPriceLevelText(place.priceLevel!),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigateButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openInMaps(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.directions, size: 18),
        label: Text(
          'result_screen.navigate'.tr(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  String? _extractCity() {
    if (place.addressComponents == null) return null;

    for (final component in place.addressComponents!.components) {
      if (component.types?.contains('locality') ?? false) {
        return component.longText ?? component.shortText;
      }
      // Fallback to administrative area if locality not found
      if (component.types?.contains('administrative_area_level_2') ?? false) {
        return component.longText ?? component.shortText;
      }
    }
    return null;
  }

  String _getPriceLevelText(String priceLevel) {
    switch (priceLevel) {
      case 'PRICE_LEVEL_INEXPENSIVE':
      case '1':
        return '\$';
      case 'PRICE_LEVEL_MODERATE':
      case '2':
        return '\$\$';
      case 'PRICE_LEVEL_EXPENSIVE':
      case '3':
        return '\$\$\$';
      case 'PRICE_LEVEL_VERY_EXPENSIVE':
      case '4':
        return '\$\$\$\$';
      default:
        return '\$\$';
    }
  }

  Future<void> _openInMaps(BuildContext context) async {
    if (place.googleMapsUri != null) {
      // Try to open Google Maps URI first
      final uri = Uri.parse(place.googleMapsUri!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fallback to coordinates if available
    if (place.location != null) {
      final lat = place.location!.latitude;
      final lng = place.location!.longitude;
      final name = Uri.encodeComponent(
        place.displayName?.text ?? 'result_screen.default_restaurant_name'.tr(),
      );

      // Try Google Maps URL scheme
      final googleMapsUrl = Uri.parse(
        'google.navigation:q=$lat,$lng&title=$name',
      );
      final googleMapsWebUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsWebUrl)) {
        await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('result_screen.maps_fail'.tr()),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // No location data available
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('result_screen.location_fail'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
