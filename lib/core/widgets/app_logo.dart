import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: ClipOval(
        child: Image.asset(
          Theme.of(context).brightness == Brightness.dark
              ? "assets/images/Dishcovery-black.png" //mode gelap
              : "assets/images/Dishcovery-white.png", //mode terang
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
