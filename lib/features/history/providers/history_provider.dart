import 'package:flutter/foundation.dart';
import '../models/history_item.dart';

class HistoryProvider with ChangeNotifier {
  final List<HistoryItem> _items = [
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

  String _searchQuery = '';

  List<HistoryItem> get items {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.dish.toLowerCase().contains(query) ||
          item.origin.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void addHistory(HistoryItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeHistory(HistoryItem item) {
    _items.remove(item);
    notifyListeners();
  }
}
