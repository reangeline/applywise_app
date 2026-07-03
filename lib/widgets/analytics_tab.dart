import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pipeline_analytics.dart';
import '../providers/resume_provider.dart';
import '../services/pipeline_service.dart';

class AnalyticsTab extends StatefulWidget {
  final VoidCallback? onOptimizePressed;

  const AnalyticsTab({super.key, this.onOptimizePressed});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  PipelineAnalytics? _data;
  bool _isLoading = true;
  String? _error;
  String? _bestResumeName;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final analytics = await PipelineService().fetchAnalytics();
      String? resumeName;
      if (analytics.bestResumeVersion != null &&
          analytics.bestResumeVersion!.resumeId.isNotEmpty) {
        try {
          final resume = await Provider.of<ResumeProvider>(context, listen: false)
              .getResumeById(analytics.bestResumeVersion!.resumeId,
                  type: 'optimized');
          resumeName = resume?.nickname ??
              resume?.targetRole ??
              analytics.bestResumeVersion!.resumeName;
        } catch (_) {
          resumeName = analytics.bestResumeVersion!.resumeName;
        }
      }
      if (mounted) {
        setState(() {
          _data = analytics;
          _bestResumeName = resumeName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      final cs = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 40, color: cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final data = _data!;
    // AnalyticsTab is embedded inside HomeDashboard's SingleChildScrollView,
    // so we render a plain Column (no nested scroll) and let the outer scroll handle it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        _MetricsGrid(data: data),
        const SizedBox(height: 20),
        _ResponseRateByScore(buckets: data.scoreRangeBuckets),
        const SizedBox(height: 18),
        _WeeklyActivity(points: data.weeklyActivity),
        const SizedBox(height: 18),
        if (data.bestResumeVersion != null) ...[
          _BestResumeCard(
            best: data.bestResumeVersion!,
            resolvedName: _bestResumeName,
          ),
          const SizedBox(height: 18),
        ],
        _StageDistribution(stages: data.stageDistribution),
        const SizedBox(height: 18),
        _CoachInsight(
          insight: data.coachInsight,
          onOptimizePressed: widget.onOptimizePressed,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Metrics Grid ─────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final PipelineAnalytics data;
  const _MetricsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _MetricCard(
          label: 'Applications',
          value: d.totalApplications.toString(),
          sub: '+${d.applicationsThisWeek} this week',
        ),
        _MetricCard(
          label: 'Response rate',
          value: '${d.responseRate.toStringAsFixed(1)}%',
          sub: d.responseRate >= 30 ? 'Above average' : 'Below average',
        ),
        _MetricCard(
          label: 'Avg ATS score',
          value: '${d.averageAtsScore.toStringAsFixed(1)}%',
          sub: d.averageAtsScore >= 75 ? 'Strong' : 'Needs improvement',
        ),
        _MetricCard(
          label: 'Interviews',
          value: d.interviewCount.toString(),
          sub: d.offerCount > 0 ? '${d.offerCount} offer(s)' : 'Keep going',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: cs.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Response Rate by ATS Score ───────────────────────────────────────────────

class _ResponseRateByScore extends StatelessWidget {
  final List<ScoreRangeBucket> buckets;
  const _ResponseRateByScore({required this.buckets});

  Color _bucketColor(double rate, ColorScheme cs) {
    if (rate >= 60) return cs.primary;
    if (rate >= 35) return const Color(0xFF5DCAA5);
    if (rate >= 15) return const Color(0xFFFAC775);
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Response rate by ATS score',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        ...buckets.map((b) {
          final color = _bucketColor(b.responseRate, cs);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    b.label,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor:
                              (b.responseRate / 100).clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${b.responseRate.round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Weekly Activity ──────────────────────────────────────────────────────────

class _WeeklyActivity extends StatelessWidget {
  final List<WeeklyPoint> points;
  const _WeeklyActivity({required this.points});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (points.isEmpty) return const SizedBox.shrink();

    final maxApps =
        max(1, points.map((w) => w.applicationCount).reduce(max));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly activity',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points
              .map((w) => Expanded(child: _WeekColumn(point: w, maxApps: maxApps)))
              .toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _LegendDot(
              color: cs.primary.withValues(alpha: 0.85),
              label: 'Applied',
            ),
            const SizedBox(width: 16),
            _LegendDot(
              color: cs.primary.withValues(alpha: 0.35),
              label: 'Responses',
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekColumn extends StatelessWidget {
  final WeeklyPoint point;
  final int maxApps;

  const _WeekColumn({required this.point, required this.maxApps});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const maxH = 80.0;
    final appH =
        (maxH * point.applicationCount / maxApps).clamp(2.0, maxH);
    // Cap resH so that appH + resH never exceeds maxH (prevents RenderFlex overflow).
    final resH =
        (maxH * point.responseCount / maxApps).clamp(0.0, maxH - appH);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: maxH,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: appH,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ),
              if (resH > 0)
                Container(
                  width: 28,
                  height: resH,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.35),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          point.weekLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.55)),
        ),
      ],
    );
  }
}

// ─── Best Resume Version ──────────────────────────────────────────────────────

class _BestResumeCard extends StatelessWidget {
  final BestResume best;
  final String? resolvedName;

  const _BestResumeCard({required this.best, this.resolvedName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best performing resume',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: cs.outline.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Icon(Icons.description,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedName ?? 'Resume...',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                    ),
                    Text(
                      '${best.responseRate.round()}% response · ${best.applicationCount} apps',
                      style: TextStyle(
                          fontSize: 11, color: cs.primary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Best',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: cs.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stage Distribution ───────────────────────────────────────────────────────

class _StageDistribution extends StatelessWidget {
  final List<StageCount> stages;
  const _StageDistribution({required this.stages});

  Color _stageColor(String stage, ColorScheme cs) {
    switch (stage.toLowerCase()) {
      case 'wishlist':
        return cs.outline;
      case 'applied':
        return cs.primary;
      case 'interview':
        return const Color(0xFFFAC775);
      case 'offer':
        return const Color(0xFF1D9E75);
      case 'rejected':
        return cs.error;
      default:
        return cs.outline;
    }
  }

  String _stageLabel(String stage) {
    if (stage.isEmpty) return stage;
    return stage[0].toUpperCase() + stage.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Applications by stage',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stages.map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: cs.outline.withValues(alpha: 0.5), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _stageColor(s.stage, cs),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_stageLabel(s.stage)} · ${s.count}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Coach Insight ────────────────────────────────────────────────────────────

class _CoachInsight extends StatelessWidget {
  final String insight;
  final VoidCallback? onOptimizePressed;

  const _CoachInsight({required this.insight, this.onOptimizePressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'AI',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach insight',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface, height: 1.5),
                ),
                if (onOptimizePressed != null)
                  TextButton(
                    onPressed: onOptimizePressed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Optimize low-score apps →',
                      style: TextStyle(color: cs.primary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
