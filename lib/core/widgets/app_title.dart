import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  final String title;
  const AppTitle({super.key, this.title = "DISHCOVERY"});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }
}
