import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─── Base shimmer box ──────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlight = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ─── Home Dashboard Skeleton ───────────────────────────────────────────────────

/// Skeleton for the home dashboard while subscription + resume data loads.
class HomeDashboardSkeleton extends StatelessWidget {
  const HomeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: greeting + bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 100, height: 14),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 160, height: 28),
                ],
              ),
              _SkeletonBox(width: 44, height: 44, borderRadius: 12),
            ],
          ),
          SizedBox(height: 24),
          // Subscription card
          _SkeletonBox(width: double.infinity, height: 120, borderRadius: 16),
          SizedBox(height: 24),
          // Quick actions title
          _SkeletonBox(width: 130, height: 20),
          SizedBox(height: 16),
          _SkeletonBox(width: double.infinity, height: 72, borderRadius: 16),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 72, borderRadius: 16),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 72, borderRadius: 16),
          SizedBox(height: 24),
          // Suggestions title
          _SkeletonBox(width: 220, height: 20),
          SizedBox(height: 16),
          _SkeletonBox(width: double.infinity, height: 68, borderRadius: 12),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 68, borderRadius: 12),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 68, borderRadius: 12),
        ],
      ),
    );
  }
}

// ─── Resume List Skeleton ──────────────────────────────────────────────────────

/// Skeleton for a single resume card row.
class _ResumeCardSkeleton extends StatelessWidget {
  const _ResumeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlight = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full skeleton for the resume list body.
class ResumeListSkeleton extends StatelessWidget {
  const ResumeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _ResumeCardSkeleton(),
        _ResumeCardSkeleton(),
        _ResumeCardSkeleton(),
        _ResumeCardSkeleton(),
      ],
    );
  }
}
