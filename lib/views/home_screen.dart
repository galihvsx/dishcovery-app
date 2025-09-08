import 'package:flutter/material.dart';

import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FilledButton(
          onPressed: () {
            MaterialPageRoute route = MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            );
            Navigator.push(context, route);
          },
          child: const Text("Open Camera"),
        ),
      ),
    );
  }
}
