import 'dart:io';
import 'package:flutter/material.dart';

class ResultImageWidget extends StatelessWidget {
  final String imagePath;

  const ResultImageWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
      ),
    );
  }
}
