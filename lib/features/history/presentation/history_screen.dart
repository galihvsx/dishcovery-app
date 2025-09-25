import 'package:flutter/material.dart';
import '../../../core/widgets/theme_switcher.dart';
import 'widgets/history_card_item.dart';
import '../models/history_item.dart';
import '../../result/presentation/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<HistoryItem> _historyItems = [
    HistoryItem(
      dish: 'Nasi Padang',
      origin: 'Sumatera Barat',
      description:
          'Nasi Padang terkenal dengan berbagai lauk pauk khas Minangkabau yang kaya rempah.',
      image: 'assets/images/nasi_padang.png',
    ),
    HistoryItem(
      dish: 'Rendang',
      origin: 'Sumatera Barat',
      description:
          'Rendang adalah masakan daging sapi bercita rasa pedas yang dimasak lama dengan santan.',
      image: 'assets/images/rendang.jpeg',
    ),
    HistoryItem(
      dish: 'Gado-gado',
      origin: 'Jakarta',
      description:
          'Gado-gado adalah salad khas Indonesia dengan saus kacang gurih.',
      image: 'assets/images/gado_gado.jpeg',
    ),
    HistoryItem(
      dish: 'Sate Ayam',
      origin: 'Jawa Tengah',
      description:
          'Sate ayam disajikan dengan bumbu kacang manis gurih dan lontong atau nasi.',
      image: 'assets/images/sate_ayam.jpg',
    ),
    HistoryItem(
      dish: 'Gudeg',
      origin: 'Yogyakarta',
      description:
          'Gudeg adalah makanan khas Yogyakarta yang terbuat dari nangka muda yang dimasak dengan santan.',
      image: 'assets/images/gudeg.jpeg',
    ),
    HistoryItem(
      dish: 'Pempek',
      origin: 'Palembang',
      description:
          'Pempek adalah makanan khas Palembang yang terbuat dari ikan dan sagu.',
      image: 'assets/images/pempek.jpg',
    ),
  ];

  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoryItem> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _historyItems;
    }
    
    return _historyItems.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.dish.toLowerCase().contains(query) ||
          item.origin.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = "";
      _isSearching = false;
    });
  }

  void _navigateToResult(HistoryItem item) {
    // Navigasi sesuai dengan constructor ResultScreen yang hanya menerima imagePath
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ResultScreen(
          imagePath: item.image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('History'),
        actions: const [ThemeSwitcher()],
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search dishes, origins, or descriptions...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Search Results Info
          if (_isSearching)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Found ${filteredItems.length} result${filteredItems.length != 1 ? 's' : ''} for "$_searchQuery"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // History List menggunakan HistoryCardItem widget
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching ? Icons.search_off : Icons.history,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching 
                              ? 'No results found for "$_searchQuery"'
                              : 'No history available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_isSearching) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return HistoryCardItem(
                        dish: item.dish,
                        origin: item.origin,
                        description: item.description,
                        imageUrl: item.image,
                        onTap: () => _navigateToResult(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}