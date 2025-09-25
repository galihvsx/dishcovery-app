import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/theme_switcher.dart';
import '../../result/presentation/result_screen.dart';
import '../providers/history_provider.dart';
import 'widgets/history_card_item.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _navigateToResult(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ResultScreen(imagePath: imagePath, fromHistory: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HistoryProvider>(context);
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: const [ThemeSwitcher()],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari makanan....",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: provider.isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: provider.clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),

          // Search Results Info
          if (provider.isSearching)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Found ${items.length} result${items.length != 1 ? 's' : ''} for "${provider.searchQuery}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // List / Empty State
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          provider.isSearching
                              ? Icons.search_off
                              : Icons.history,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.isSearching
                              ? 'No results found for "${provider.searchQuery}"'
                              : 'No history available',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return HistoryCardItem(
                        dish: item.dish,
                        origin: item.origin,
                        description: item.description,
                        imageUrl: item.image,
                        onTap: () => _navigateToResult(context, item.image),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
