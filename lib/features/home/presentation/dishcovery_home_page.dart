import 'package:dishcovery_app/core/models/feed_model.dart';
import 'package:flutter/material.dart';

class DishcoveryHomePage extends StatefulWidget {
  const DishcoveryHomePage({super.key});

  static const String path = '/home';

  @override
  State<DishcoveryHomePage> createState() => _DishcoveryHomePageState();
}

class _DishcoveryHomePageState extends State<DishcoveryHomePage> {
  late List<FeedItem> _feedItems;

  @override
  void initState() {
    super.initState();
    _loadFeedData();
  }

  void _loadFeedData() {
    setState(() {
      _feedItems = FakeFeedData.generateFakeFeedItems();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          _loadFeedData();
        },
        child: ListView.builder(
          itemCount: _feedItems.length,
          itemBuilder: (context, index) {
            final item = _feedItems[index];
            return Text(item.username);
          },
        ),
      ),
    );
  }
}
