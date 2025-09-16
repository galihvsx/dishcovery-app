import 'package:flutter/material.dart';
import '../../../core/widgets/theme_switcher.dart';
import 'widgets/history_card_item.dart';
import '../models/history_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<HistoryItem> _historyItems = [
    HistoryItem(
      dish: 'Nasi Padang',
      origin: 'Sumatera Barat',
      description:
          'Nasi Padang terkenal dengan berbagai lauk pauk khas Minangkabau yang kaya rempah.',
      image: 'assets/images/nasi_padang.jpg',
    ),
    HistoryItem(
      dish: 'Rendang',
      origin: 'Sumatera Barat',
      description:
          'Rendang adalah masakan daging sapi bercita rasa pedas yang dimasak lama dengan santan.',
      image: 'assets/images/rendang.jpg',
    ),
    HistoryItem(
      dish: 'Gado-gado',
      origin: 'Jakarta',
      description:
          'Gado-gado adalah salad khas Indonesia dengan saus kacang gurih.',
      image: 'assets/images/gado_gado.jpg',
    ),
    HistoryItem(
      dish: 'Sate Ayam',
      origin: 'Jawa Tengah',
      description:
          'Sate ayam disajikan dengan bumbu kacang manis gurih dan lontong atau nasi.',
      image: 'assets/images/sate_ayam.jpg',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('History'),
        actions: const [ThemeSwitcher()],
      ),
      body: _historyItems.isEmpty
          ? const Center(child: Text('No history yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _historyItems.length,
              itemBuilder: (context, index) {
                final item = _historyItems[index];
                return HistoryCardItem(
                  dish: item.dish,
                  origin: item.origin,
                  description: item.description,
                  imageUrl: item.image,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing ${item.dish}')),
                    );
                  },
                );
              },
            ),
    );
  }
}
