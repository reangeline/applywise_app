import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../models/onboarding_models.dart';
import '../../models/resume.dart';
import '../../providers/onboarding_provider.dart';
import '../resume/resume_manual_form.dart';
import 'onboarding_signup_screen.dart';

class ScorePartialScreen extends StatelessWidget {
  const ScorePartialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<OnboardingProvider>().atsResult;
    if (result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final score = result.score;
    final Color scoreColor = score < 50
        ? AppTheme.errorColor
        : score < 75
            ? const Color(0xFFF59E0B)
            : AppTheme.successColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildScoreCard(context, score, scoreColor),
              const SizedBox(height: 20),
              if (result.totalIssues > 0)
                _buildIssuesBanner(context, result.totalIssues),
              const SizedBox(height: 20),
              _buildCategoriesSection(context, result),
              const SizedBox(height: 32),
              _buildCta(context, score),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Result',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'See how your resume performs in ATS systems.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(
      BuildContext context, int score, Color scoreColor) {
    final String label = score < 50
        ? 'Resume too weak for ATS'
        : score < 75
            ? 'Resume needs improvements'
            : 'Resume in good shape';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: scoreColor.withValues(alpha: 0.3), width: 2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'ATS Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          _ScoreCircle(score: score, color: scoreColor),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.errorColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count critical issue${count == 1 ? '' : 's'} identified',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(
      BuildContext context, OnboardingAtsResult result) {
    final categories = result.problemCategories;

    // Extract first real keyword detail from rawData
    final parsed =
        result.rawData['parsed_data'] as Map<String, dynamic>? ?? result.rawData;
    final missing = <String>[];
    final mr = parsed['missing_requirements'];
    if (mr is List) missing.addAll(mr.map((e) => e.toString()));
    if (missing.isEmpty) {
      final rmr = result.rawData['missing_requirements'];
      if (rmr is List) missing.addAll(rmr.map((e) => e.toString()));
    }
    final firstDetail = missing.isNotEmpty ? missing.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Problem Categories',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Sign up to see all details and fix suggestions.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        if (categories.isNotEmpty)
          _UnlockedCategoryRow(
            label: categories.first,
            detail: firstDetail,
          ),
        ...categories.skip(1).map((cat) => _LockedCategoryRow(label: cat)),
        const SizedBox(height: 16),
        _buildProgressHint(context),
      ],
    );
  }

  Widget _buildProgressHint(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.25,
            minHeight: 6,
            backgroundColor:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "You're 1 step away from seeing everything",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCta(BuildContext context, int score) {
    final parsedData =
        context.read<OnboardingProvider>().parsedResumeData;
    final hasParsedData = parsedData != null;

    final String ctaLabel = hasParsedData
        ? 'Review & Edit Your Resume'
        : score < 60
            ? 'Fix critical issues — free for 7 days'
            : score < 80
                ? 'See all issues and fix them free'
                : 'Fine-tune your resume for free';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (hasParsedData) {
                // PDF mode: open edit form so user can review parsed data,
                // then the form navigates to signup on save.
                final initialResume = Resume.fromJson({
                  'parsed_data': parsedData,
                  'type': 'manual',
                  'id': '',
                  'created_at': DateTime.now().toIso8601String(),
                });
                Navigator.of(context).push(
                  AppTransitions.slideRight(
                    ResumeManualForm(
                      initialResume: initialResume,
                      forceCreate: true,
                      isOnboardingMode: true,
                    ),
                  ),
                );
              } else {
                // Manual text mode: go directly to signup.
                Navigator.of(context).push(
                  AppTransitions.slideUp(const OnboardingSignupScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              ctaLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Create your free account to see the full analysis.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Score circle ────────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreCircle({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 12,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
              ),
              Text(
                '/100',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Unlocked category row (first category only) ─────────────────────────────

class _UnlockedCategoryRow extends StatelessWidget {
  final String label;
  final String? detail;

  const _UnlockedCategoryRow({required this.label, this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (detail != null) ...
                    [
                      const SizedBox(height: 4),
                      Text(
                        detail!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Preview',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Locked category row ─────────────────────────────────────────────────────

class _LockedCategoryRow extends StatelessWidget {
  final String label;

  const _LockedCategoryRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  // Blurred placeholder for the locked details
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.lock_outline,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
