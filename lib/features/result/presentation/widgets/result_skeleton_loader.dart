// lib/features/result/presentation/widgets/result_skeleton_loader.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ResultSkeletonLoader extends StatelessWidget {
  const ResultSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton for Image
            _SkeletonBox(height: 200, width: double.infinity),
            SizedBox(height: 16),

            // Skeleton for Title and Origin
            _SkeletonBox(height: 28, width: 200),
            SizedBox(height: 8),
            _SkeletonBox(height: 14, width: 120),
            SizedBox(height: 24),

            // Skeleton for a block of text (Description/History)
            _SkeletonBox(height: 18, width: 150),
            SizedBox(height: 8),
            _SkeletonBox(height: 14, width: double.infinity),
            SizedBox(height: 8),
            _SkeletonBox(height: 14, width: double.infinity),
            SizedBox(height: 8),
            _SkeletonBox(height: 14, width: 250),
            SizedBox(height: 24),

            // Skeleton for another block of text (Ingredients/Steps)
            _SkeletonBox(height: 18, width: 150),
            SizedBox(height: 8),
            _SkeletonBox(height: 14, width: double.infinity),
            SizedBox(height: 8),
            _SkeletonBox(height: 14, width: double.infinity),
            SizedBox(height: 8),
            _SkeletonBox(height: 14, width: 250),
          ],
        ),
      ),
    );
  }
}

// Helper widget to create the gray boxes
class _SkeletonBox extends StatelessWidget {
  final double height;
  final double width;

  const _SkeletonBox({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
