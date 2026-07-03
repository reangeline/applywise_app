import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job_application.dart';
import '../providers/pipeline_provider.dart';
import '../screens/pipeline/add_job_confirm_screen.dart';
import '../screens/pipeline/job_detail_screen.dart';
import '../screens/resume/resume_optimizer_screen.dart';
import 'analytics_tab.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const Color _primaryTeal = Color(0xFF1D9E75);

// ─── Internal data model ──────────────────────────────────────────────────────
//
// JobApplication (from lib/models/job_application.dart) is used directly.

// ─── Hardcoded sample data (kept for reference — now seeded in PipelineProvider)
// ignore_for_file: unused_element
const List<JobApplication> _kInitialApplied = [
  JobApplication(
    companyInitials: 'ST',
    logoBackground: Color(0xFFE6F1FB),
    logoTextColor: Color(0xFF185FA5),
    jobTitle: 'Senior iOS Dev',
    companyName: 'Stripe',
    dateApplied: 'Mar 23',
    resumeVersion: 'v3 — Tech',
    atsScore: 87,
    stage: 'Applied',
  ),
  JobApplication(
    companyInitials: 'LI',
    logoBackground: Color(0xFFFBEAF0),
    logoTextColor: Color(0xFF993556),
    jobTitle: 'Mobile Engineer',
    companyName: 'Linear',
    dateApplied: 'Mar 27',
    resumeVersion: 'v3 — Tech',
    atsScore: 64,
    stage: 'Applied',
  ),
];

const List<JobApplication> _kInitialInterview = [
  JobApplication(
    companyInitials: 'SH',
    logoBackground: Color(0xFFEAF3DE),
    logoTextColor: Color(0xFF3B6D11),
    jobTitle: 'Flutter Lead',
    companyName: 'Shopify',
    dateApplied: 'Mar 18',
    resumeVersion: 'v4 — Lead',
    atsScore: 91,
    stage: 'Interview',
  ),
  JobApplication(
    companyInitials: 'NO',
    logoBackground: Color(0xFFFAEEDA),
    logoTextColor: Color(0xFF854F0B),
    jobTitle: 'Staff Engineer',
    companyName: 'Notion',
    dateApplied: 'Mar 15',
    resumeVersion: 'v2 — Sr.',
    atsScore: 72,
    stage: 'Interview',
  ),
];

const List<JobApplication> _kInitialOffer = [
  JobApplication(
    companyInitials: 'FI',
    logoBackground: Color(0xFFE1F5EE),
    logoTextColor: Color(0xFF085041),
    jobTitle: 'iOS Engineer',
    companyName: 'Figma',
    dateApplied: 'Mar 10',
    resumeVersion: 'v4 — Lead',
    atsScore: 94,
    stage: 'Offer',
  ),
];

const List<JobApplication> _kInitialRejected = [
  JobApplication(
    companyInitials: 'ME',
    logoBackground: Color(0xFFF1EFE8),
    logoTextColor: Color(0xFF5F5E5A),
    jobTitle: 'Mobile Dev',
    companyName: 'Meta',
    dateApplied: 'Mar 5',
    resumeVersion: 'v1',
    atsScore: 58,
    stage: 'Rejected',
    opacity: 0.55,
  ),
];

// ─── NudgeCoachBanner ─────────────────────────────────────────────────────────

class NudgeCoachBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const NudgeCoachBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg    = isDark ? const Color(0xFF0D2B1E) : const Color(0xFFE1F5EE);
    final bannerBorder = isDark ? const Color(0xFF1D6047) : const Color(0xFF5DCAA5);
    final textColor   = isDark ? const Color(0xFF5DCAA5) : const Color(0xFF085041);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bannerBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bannerBorder, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 11, color: textColor),
                  children: const [
                    TextSpan(
                      text: 'Follow-up coach: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          '7 days without response from Stripe. Time to send a message?',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _DashedBorderPainter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color dashColor;
  const _DashedBorderPainter({required this.dashColor});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;

    final paint = Paint()
      ..color = dashColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.dashColor != dashColor;
}

// ─── AddJobPlaceholder ────────────────────────────────────────────────────────

class AddJobPlaceholder extends StatelessWidget {
  final VoidCallback? onTap;

  const AddJobPlaceholder({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashColor = isDark ? const Color(0xFF4A4D5E) : const Color(0xFFBDBDBD);
    final labelColor = isDark ? const Color(0xFF6B7280) : const Color(0xFFBDBDBD);
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(dashColor: dashColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: labelColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'Add job to pipeline',
                style: TextStyle(fontSize: 12, color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── JobCard ──────────────────────────────────────────────────────────────────

class JobCard extends StatelessWidget {
  final String companyInitials;
  final Color companyBackground;
  final Color companyTextColor;
  final String jobTitle;
  final String companyName;
  final String dateApplied;
  final String resumeVersion;
  final int atsScore;
  final double opacity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const JobCard({
    super.key,
    required this.companyInitials,
    required this.companyBackground,
    required this.companyTextColor,
    required this.jobTitle,
    required this.companyName,
    required this.dateApplied,
    required this.resumeVersion,
    required this.atsScore,
    this.opacity = 1.0,
    this.onTap,
    this.onLongPress,
  });

  Color get _atsBg {
    if (atsScore >= 80) return const Color(0xFFE1F5EE);
    if (atsScore >= 60) return const Color(0xFFFAEEDA);
    return const Color(0xFFFCEBEB);
  }

  Color get _atsText {
    if (atsScore >= 80) return const Color(0xFF0F6E56);
    if (atsScore >= 60) return const Color(0xFF854F0B);
    return const Color(0xFFA32D2D);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final cardBg      = cs.surface;
    final borderColor = isDark ? const Color(0xFF2D3144) : const Color(0xFFE0E0E0);
    final titleColor  = cs.onSurface;
    final subColor    = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF888888);
    final divColor    = isDark ? const Color(0xFF2D3144) : const Color(0xFFF0F0F0);
    final dateColor   = isDark ? const Color(0xFF6B7280) : const Color(0xFFAAAAAA);
    final tagBg       = isDark ? const Color(0xFF2D3144) : const Color(0xFFF5F5F5);
    final tagColor    = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF888888);
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row: company logo + ATS score badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: companyBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          companyInitials,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: companyTextColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _atsBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$atsScore%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _atsText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Job title
                  const SizedBox(height: 6),
                  Text(
                    jobTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  // Company name
                  const SizedBox(height: 2),
                  Text(
                    companyName,
                    style: TextStyle(
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  // Divider
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: divColor,
                  ),
                  // Bottom row: date + resume version tag
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateApplied,
                        style: TextStyle(
                          fontSize: 11,
                          color: dateColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          resumeVersion,
                          style: TextStyle(
                            fontSize: 10,
                            color: tagColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _PendingJobCard ──────────────────────────────────────────────────────────

class _PendingJobCard extends StatelessWidget {
  final PendingJob pending;
  final VoidCallback onTap;

  const _PendingJobCard({required this.pending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const amber = Color(0xFFF59E0B);
    const completedGreen = Color(0xFF0F6E56);
    final (logoBg, logoText) = PipelineProvider.logoColors(pending.company);
    final initials = PipelineProvider.companyInitials(pending.company);
    final isComplete = pending.optimizedResume?.score != null;
    final borderColor = isComplete ? completedGreen : amber;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Company logo circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: logoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: logoText,
                      ),
                    ),
                  ),
                  // "Tap to confirm" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tap to confirm',
                      style: TextStyle(
                        fontSize: 10,
                        color: borderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pending.role.isNotEmpty ? pending.role : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pending.company.isNotEmpty ? pending.company : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 0.5,
                color: borderColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 6),
              if (pending.optimizedResume?.score != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 12, color: Color(0xFF0F6E56)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Optimization complete · ${pending.optimizedResume!.score!.toStringAsFixed(0)}% match',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF0F6E56)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        size: 12, color: amber),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Optimization in progress…',
                        style: TextStyle(fontSize: 11, color: amber),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Job card long-press options ─────────────────────────────────────────────

void _showJobCardOptions(
  BuildContext context,
  JobApplication job,
  PipelineProvider pipeline,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive'),
            subtitle: const Text('Hide from the board'),
            onTap: () {
              Navigator.pop(context);
              pipeline.archiveJob(job);
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: const Text('View details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(job: job),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ─── _KanbanColumn ────────────────────────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final String stage;
  final List<JobApplication> jobs;
  final bool showAddPlaceholder;
  final VoidCallback? onAddJobTap;
  final List<PendingJob> pendingJobs;

  const _KanbanColumn({
    required this.stage,
    required this.jobs,
    this.showAddPlaceholder = false,
    this.onAddJobTap,
    this.pendingJobs = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column header: label + count badge
          Row(
            children: [
              Text(
                stage.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2D3144)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${jobs.length + pendingJobs.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final pendingJob in pendingJobs)
            _PendingJobCard(
              pending: pendingJob,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddJobConfirmScreen(
                      pendingJobId: pendingJob.id,
                      company: pendingJob.company,
                      role: pendingJob.role,
                      location: pendingJob.location,
                      resumeId: pendingJob.resumeId,
                      resumeLabel: pendingJob.resumeLabel,
                      optimizedResume: pendingJob.optimizedResume,
                      onJobAdded: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          // Job cards — plain Column avoids shrinkWrap issues in nested scroll views
          for (final j in jobs)
            JobCard(
              companyInitials: j.companyInitials,
              companyBackground: j.logoBackground,
              companyTextColor: j.logoTextColor,
              jobTitle: j.jobTitle,
              companyName: j.companyName,
              dateApplied: j.dateApplied,
              resumeVersion: j.resumeVersion,
              atsScore: j.atsScore,
              opacity: j.opacity,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(job: j),
                ),
              ),
              onLongPress: () => _showJobCardOptions(
                context,
                j,
                Provider.of<PipelineProvider>(context, listen: false),
              ),
            ),
          // AddJobPlaceholder only for the Applied column
          if (showAddPlaceholder)
            AddJobPlaceholder(onTap: onAddJobTap),
        ],
      ),
    );
  }
}

// ─── _PipelineTab ─────────────────────────────────────────────────────────────

class _PipelineTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PipelineTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _primaryTeal : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
            color:
                isActive ? _primaryTeal : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }
}

// ─── PipelineSection ─────────────────────────────────────────────────────────

class PipelineSection extends StatefulWidget {
  final VoidCallback? onAddJobTap;

  const PipelineSection({super.key, this.onAddJobTap});

  @override
  State<PipelineSection> createState() => _PipelineSectionState();
}

class _PipelineSectionState extends State<PipelineSection> {
  int _selectedTab = 0;

  void _showArchivedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _ArchivedJobsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = Provider.of<PipelineProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header: title only
        Text(
          'My pipeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        // Tab labels
        Row(
          children: [
            _PipelineTab(
              label: 'Board',
              isActive: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            const SizedBox(width: 16),
            _PipelineTab(
              label: 'Analytics',
              isActive: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tab content
        if (_selectedTab == 1)
          AnalyticsTab(
            onOptimizePressed: widget.onAddJobTap,
          )
        else ...[
          // Horizontally scrollable Kanban board
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KanbanColumn(
                  stage: 'Wishlist',
                  jobs: pipeline.jobsForStage('Wishlist'),
                  showAddPlaceholder: true,
                  onAddJobTap: widget.onAddJobTap ?? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResumeOptimizerScreen(),
                    ),
                  ),
                  pendingJobs: pipeline.pendingJobs,
                ),
                _KanbanColumn(
                  stage: 'Applied',
                  jobs: pipeline.jobsForStage('Applied'),
                ),
                _KanbanColumn(
                  stage: 'Interview',
                  jobs: pipeline.jobsForStage('Interview'),
                ),
                _KanbanColumn(
                  stage: 'Offer',
                  jobs: pipeline.jobsForStage('Offer'),
                ),
                _KanbanColumn(
                  stage: 'Accepted',
                  jobs: pipeline.jobsForStage('Accepted'),
                ),
                _KanbanColumn(
                  stage: 'Rejected',
                  jobs: pipeline.jobsForStage('Rejected'),
                ),
              ],
            ),
          ),
          // Archived jobs link
          Consumer<PipelineProvider>(
            builder: (_, pipe, __) {
              final count = pipe.archivedJobs.length;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: _showArchivedSheet,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.archive_outlined,
                          size: 13, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Text(
                        'Archived ($count)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// ─── _ArchivedJobsSheet ───────────────────────────────────────────────────────

class _ArchivedJobsSheet extends StatelessWidget {
  const _ArchivedJobsSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<PipelineProvider>(
      builder: (context, pipeline, _) {
        final archived = pipeline.archivedJobs;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.archive_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Archived (${archived.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (archived.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No archived jobs',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: archived.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ArchivedJobTile(job: archived[i]),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─── _ArchivedJobTile ─────────────────────────────────────────────────────────

class _ArchivedJobTile extends StatelessWidget {
  final JobApplication job;

  const _ArchivedJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg   = isDark ? const Color(0xFF222535) : const Color(0xFFF5F5F5);
    final titleClr = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final subClr   = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF888888);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: job.logoBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              job.companyInitials,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: job.logoTextColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: titleClr,
                  ),
                ),
                Text(
                  '${job.companyName} · ${job.stage}',
                  style: TextStyle(fontSize: 12, color: subClr),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () =>
                Provider.of<PipelineProvider>(context, listen: false)
                    .unarchiveJob(job),
            style: TextButton.styleFrom(
              foregroundColor: _primaryTeal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Unarchive', style: TextStyle(fontSize: 12)),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(job: job),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            color: subClr,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
