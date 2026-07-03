import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/job_application.dart';
import '../../models/resume.dart';
import '../../providers/pipeline_provider.dart';
import '../../providers/resume_provider.dart';
import '../../services/pipeline_service.dart';

const _stages = ['Wishlist', 'Applied', 'Interview', 'Offer', 'Rejected'];

class AddJobConfirmScreen extends StatefulWidget {
  final String? pendingJobId;
  final String company;
  final String role;
  final String? location;
  final String? resumeId;
  final String resumeLabel;
  /// The [Resume] object returned immediately by the optimize POST.
  /// If its [Resume.score] is null the screen will poll the API in background
  /// until the async processing completes.
  final Resume? optimizedResume;
  final VoidCallback? onJobAdded;

  const AddJobConfirmScreen({
    super.key,
    this.pendingJobId,
    required this.company,
    required this.role,
    this.location,
    this.resumeId,
    required this.resumeLabel,
    this.optimizedResume,
    this.onJobAdded,
  });

  @override
  State<AddJobConfirmScreen> createState() => _AddJobConfirmScreenState();
}

class _AddJobConfirmScreenState extends State<AddJobConfirmScreen> {
  String _stage = 'Wishlist';
  Resume? _optimized;
  bool _polling = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _optimized = widget.optimizedResume;
    // If a resume was returned but the worker hasn't finished yet, poll.
    if (widget.optimizedResume != null && widget.optimizedResume!.score == null) {
      _startPolling();
    }
  }

  Future<void> _startPolling() async {
    if (!mounted) return;
    setState(() => _polling = true);
    try {
      final resumeId = widget.optimizedResume!.id;
      final result = await Provider.of<ResumeProvider>(context, listen: false)
          .pollOptimizedResume(resumeId);
      if (mounted) {
        setState(() {
          _optimized = result;
          _polling = false;
        });
        // Persist the completed resume back into the pending job so that
        // re-opening the card from the pipeline board skips polling.
        final pipeline = Provider.of<PipelineProvider>(context, listen: false);
        final pendingJobId = widget.pendingJobId;
        if (pendingJobId != null) {
          pipeline.updatePendingJobResume(pendingJobId, result);
        } else {
          pipeline.updatePendingJobResumeByResumeId(resumeId, result);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _polling = false);
    }
  }

  Future<void> _addToPipeline() async {
    if (_saving) return;
    setState(() => _saving = true);

    final pipeline = Provider.of<PipelineProvider>(context, listen: false);
    final (logoBg, logoText) = PipelineProvider.logoColors(widget.company);

    try {
      // Persist to backend to obtain a real job id for AI coach calls.
      final req = CreateJobRequest(
        companyName: widget.company.isEmpty ? 'Company' : widget.company,
        jobTitle: widget.role.isEmpty ? 'Role' : widget.role,
        location: widget.location ?? '',
        stage: _stage,
        resumeId: _optimized?.id ?? widget.resumeId ?? '',
        atsScore: _optimized?.score?.toInt() ?? 0,
        missingKeywords:
            _optimized?.missingRequirements?.cast<String>() ?? [],
      );
      final savedJob = await PipelineService().createJob(req);

      // Guard: the screen may have been dismissed (back gesture) while the
      // network call was in-flight.  If so, skip local state mutations.
      if (!mounted) return;

      // Use the score from the optimized resume, falling back to what the
      // backend returned in savedJob (which already received ats_score).
      final resolvedAtsScore = _optimized?.score?.toInt() != null && _optimized!.score! > 0
          ? _optimized!.score!.toInt()
          : savedJob.atsScore;

      // Add optimistically for instant UI feedback using local display fields
      // (colors, initials) that the backend doesn't store.
      final job = JobApplication(
        id: savedJob.id,
        companyInitials: PipelineProvider.companyInitials(widget.company),
        logoBackground: logoBg,
        logoTextColor: logoText,
        jobTitle: widget.role.isEmpty ? 'Role' : widget.role,
        companyName: widget.company.isEmpty ? 'Company' : widget.company,
        dateApplied: DateFormat.MMMd().format(DateTime.now()),
        resumeVersion: widget.resumeLabel,
        atsScore: resolvedAtsScore,
        stage: _stage,
        resumeId: _optimized?.id ?? widget.resumeId,
        location: widget.location,
        missingKeywords:
            _optimized?.missingRequirements?.cast<String>() ?? [],
      );

      // 1. Keep a local fallback so a transient refresh failure doesn't hide
      //    a card that was already created successfully on the backend.
      pipeline.addOrReplaceJob(job);

      // 2. Immediately fetch the full server list. This is the source of truth
      //    and prevents the local optimistic card from replacing older cards.
      await pipeline.refresh();

      // 3. If the refresh failed or the backend response was delayed, keep the
      //    fallback local card instead of leaving the board empty.
      if (!pipeline.jobs.any((existing) => existing.id == job.id)) {
        pipeline.addOrReplaceJob(job);
      }

      final pendingJobId = widget.pendingJobId;
      if (pendingJobId != null) {
        pipeline.removePendingJob(pendingJobId);
      }
      widget.onJobAdded?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Text(
                'Your resume has been sent\nfor optimization!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'The optimized version will appear in your resumes shortly. '
                'Now add this job to your pipeline.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
              ),

              const SizedBox(height: 24),

              // ── Optimization notice ──────────────────────────────────────────
              if (widget.optimizedResume != null) ...[
                _OptimizationNotice(
                  optimized: _optimized,
                  polling: _polling,
                  resumeLabel: widget.resumeLabel,
                ),
                const SizedBox(height: 24),
              ],

              // ── Job summary ──────────────────────────────────────────────────
              const _SectionTitle('Job details'),
              const SizedBox(height: 12),
              _FieldRow(label: 'Company', value: widget.company.isEmpty ? '—' : widget.company),
              _FieldRow(label: 'Role', value: widget.role.isEmpty ? '—' : widget.role),
              if (widget.location != null && widget.location!.isNotEmpty)
                _FieldRow(label: 'Location', value: widget.location!),
              if (widget.resumeLabel.isNotEmpty)
                _FieldRow(label: 'Resume', value: widget.resumeLabel),

              const SizedBox(height: 28),

              // ── Stage selector ────────────────────────────────────────────
              const _SectionTitle('Pipeline stage'),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _stages.map((s) {
                    final isActive = s == _stage;
                    return GestureDetector(
                      onTap: () => setState(() => _stage = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? cs.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isActive
                              ? null
                              : Border.all(
                                  color: cs.outline.withValues(alpha: 0.5),
                                ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? cs.onPrimary
                                : cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 40),

              // ── Add to Pipeline button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_saving || _polling) ? null : _addToPipeline,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_task_rounded),
                  label: Text(_saving ? 'Saving…' : 'Add to Pipeline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Optimization notice ───────────────────────────────────────────────────────

class _OptimizationNotice extends StatelessWidget {
  final Resume? optimized;
  final bool polling;
  final String resumeLabel;

  const _OptimizationNotice({
    required this.optimized,
    required this.polling,
    required this.resumeLabel,
  });

  Color _scoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isReady = optimized?.score != null;

    // ── Still processing ────────────────────────────────────────────────────
    if (!isReady) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (polling)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            else
              Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                polling
                    ? 'Optimizing your resume…'
                    : 'Your resume is being optimized. The match score and updated resume will appear shortly on the pipeline card.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Optimization complete — show results ─────────────────────────────────
    final score = optimized!.score!;
    final scoreColor = _scoreColor(score);
    final suggestions = optimized!.suggestions ?? [];
    final missing = optimized!.missingRequirements ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resume used — topo em destaque
          if (resumeLabel.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.description_outlined,
                    size: 13, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 5),
                Text(
                  'Based on  ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                ),
                Expanded(
                  child: Text(
                    resumeLabel,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.8),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.5,
                color: scoreColor.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
          ],
          // Score row
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: scoreColor),
              const SizedBox(width: 8),
              Text(
                'Resume optimized!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${score.toStringAsFixed(0)}% match',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (suggestions.isNotEmpty) ...[  
            const SizedBox(height: 12),
            Text(
              'Improvements applied',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            ...suggestions.take(3).map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_outline_rounded,
                          size: 13, color: scoreColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (missing.isNotEmpty) ...[  
            const SizedBox(height: 10),
            Text(
              'Missing keywords',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: missing.take(5).map(
                (m) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    m,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

