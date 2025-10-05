import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:dishcovery_app/core/models/place_model.dart';
import 'package:dishcovery_app/core/services/places_api_service.dart';
import 'package:dishcovery_app/features/result/widgets/restaurant_card.dart';

class NearbyRestaurantsSection extends StatefulWidget {
  final String foodName;
  final bool autoLoad;

  const NearbyRestaurantsSection({
    super.key,
    required this.foodName,
    this.autoLoad = true,
  });

  @override
  State<NearbyRestaurantsSection> createState() =>
      _NearbyRestaurantsSectionState();
}

class _NearbyRestaurantsSectionState extends State<NearbyRestaurantsSection> {
  final PlacesApiService _placesService = PlacesApiService.instance;
  List<PlaceModel>? _restaurants;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadNearbyRestaurants();
    }
  }

  @override
  void didUpdateWidget(NearbyRestaurantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foodName != widget.foodName) {
      _loadNearbyRestaurants();
    }
  }

  Future<void> _loadNearbyRestaurants() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user location
      _userLocation = await _placesService.getCurrentLocation();

      // Search for restaurants
      final response = await _placesService.searchNearbyRestaurants(
        foodName: widget.foodName,
        location: _userLocation,
        radius: 5000, // 5km radius
        maxResults: 10,
        includeOnlyOpenNow: false,
        minRating: 3.5, // Only show restaurants with 3.5+ rating
      );

      if (mounted) {
        setState(() {
          _restaurants = response.places;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('API key')) {
      return 'API key not configured. Please add your Google Places API key.';
    } else if (error.toString().contains('Location')) {
      return 'Unable to get your location. Please enable location services.';
    } else if (error.toString().contains('Network')) {
      return 'No internet connection. Please check your network.';
    } else {
      return 'Unable to find nearby restaurants. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby Restaurants',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Serving ${widget.foodName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (!_isLoading && _restaurants != null)
                IconButton(
                  onPressed: _loadNearbyRestaurants,
                  icon: const Icon(Icons.refresh, size: 18),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          _buildLoadingState()
        else if (_errorMessage != null)
          _buildErrorState(context)
        else if (_restaurants == null || _restaurants!.isEmpty)
          _buildEmptyState(context)
        else
          _buildRestaurantsList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 240,
      child: Skeletonizer(
        enabled: true,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.1),
                     blurRadius: 8,
                     offset: const Offset(0, 2),
                   ),
                 ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: const Bone.square(size: 120),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 2),
                        const SizedBox(height: 8),
                        Bone.text(words: 3),
                        const SizedBox(height: 4),
                        Bone.text(words: 2),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNearbyRestaurants,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No restaurants found nearby',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different location or broader search',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsList() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _restaurants!.length,
        itemBuilder: (context, index) {
          final restaurant = _restaurants![index];

          // Calculate distance if user location is available
          String? distance;
          if (_userLocation != null && restaurant.location != null) {
            final distanceInKm = _placesService.calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              restaurant.location!.latitude!,
              restaurant.location!.longitude!,
            );
            distance = '${distanceInKm.toStringAsFixed(1)} km';
          }

          return RestaurantCard(
            place: restaurant,
            onTap: () {
              // Optional: Add detail page navigation
              _showRestaurantDetails(context, restaurant, distance);
            },
          );
        },
      ),
    );
  }

  void _showRestaurantDetails(
    BuildContext context,
    PlaceModel restaurant,
    String? distance,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.displayName?.text ?? 'Restaurant',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (distance != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Add more details here as needed
          ],
        ),
      ),
    );
  }
}
