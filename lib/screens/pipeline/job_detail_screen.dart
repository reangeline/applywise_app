import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../config/theme.dart';
import '../../models/contact.dart';
import '../../models/job_application.dart';
import '../../models/resume.dart';
import '../../providers/pipeline_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/pipeline_service.dart';
import '../../widgets/follow_up_coach_sheet.dart';
import '../../widgets/interview_schedule_sheet.dart';
import '../resume/resume_manual_form.dart';

// ─── JobDetailScreen ──────────────────────────────────────────────────────────

class JobDetailScreen extends StatefulWidget {
  final JobApplication job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late JobApplication _job;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  void _onJobUpdated(JobApplication updated) {
    if (!mounted) return;
    setState(() => _job = updated);
    Provider.of<PipelineProvider>(context, listen: false).updateJob(updated);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                children: [
                  _CoachTab(job: _job, onJobUpdated: _onJobUpdated),
                  _AtsMatchTab(job: _job),
                  _ContactsTab(job: _job),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final txtColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final divColor = isDark ? const Color(0xFF2D3144) : const Color(0xFFE0E0E0);
    return AppBar(
      elevation: 0,
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: Color(0xFF1D9E75),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        _job.companyName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: txtColor,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              _job.stage,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Divider(height: 0.5, thickness: 0.5, color: divColor),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Color(0xFF1D9E75), width: 2),
      ),
      labelColor: const Color(0xFF1D9E75),
      unselectedLabelColor: const Color(0xFF888888),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      dividerColor: isDark ? const Color(0xFF2D3144) : const Color(0xFFE0E0E0),
      tabs: const [
        Tab(text: 'Coach'),
        Tab(text: 'ATS Match'),
        Tab(text: 'Contacts'),
      ],
    );
  }
}

// ─── Tab 1: Coach ─────────────────────────────────────────────────────────────

class _CoachTab extends StatefulWidget {
  final JobApplication job;
  final void Function(JobApplication updated) onJobUpdated;

  const _CoachTab({required this.job, required this.onJobUpdated});

  @override
  State<_CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<_CoachTab> {
  String? _coachContent;
  bool _loadingCoach = false;
  String? _coachError;
  bool _isPremiumRequired = false;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    _loadCoachContent();
  }

  @override
  void didUpdateWidget(_CoachTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload coach when stage or job id changes (e.g. Wishlist → Applied)
    if (oldWidget.job.stage != widget.job.stage ||
        oldWidget.job.id != widget.job.id) {
      _coachContent = null;
      _coachError = null;
      _loadCoachContent();
    }
  }
  int get _daysSinceApplied {
    final parts = widget.job.dateApplied.split(' ');
    if (parts.length == 2) {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final month = months[parts[0]];
      final day = int.tryParse(parts[1]);
      if (month != null && day != null) {
        final now = DateTime.now();
        final applied = DateTime(now.year, month, day);
        return now.difference(applied).inDays.abs();
      }
    }
    return 0;
  }

  Future<void> _loadCoachContent() async {
    if (widget.job.stage == 'Wishlist') return;
    if (widget.job.id.isEmpty) return;

    // Skip if already known to require premium
    if (_isPremiumRequired) return;

    // Check subscription before hitting API
    final isPro = Provider.of<SubscriptionProvider>(context, listen: false).isPro;
    if (!isPro) {
      setState(() => _isPremiumRequired = true);
      return;
    }

    // Return cached content immediately without hitting the API
    final cached = PipelineService.getCachedCoach(widget.job.id, widget.job.stage);
    if (cached != null) {
      setState(() => _coachContent = cached);
      return;
    }

    setState(() {
      _loadingCoach = true;
      _coachError = null;
    });
    try {
      final content = await PipelineService().generateCoachContent(
        jobId: widget.job.id,
        stage: widget.job.stage,
        jobTitle: widget.job.jobTitle,
        companyName: widget.job.companyName,
        location: widget.job.location,
        atsScore: widget.job.atsScore,
        resumeVersion: widget.job.resumeVersion,
        jobDescription: widget.job.jobDescription,
        jobUrl: widget.job.jobUrl,
        matchedKeywords: widget.job.matchedKeywords,
        missingKeywords: widget.job.missingKeywords,
        daysSinceApplied: _daysSinceApplied,
      );
      if (mounted) setState(() => _coachContent = content);
    } catch (e) {
      // 403 = plano vencido ou sem créditos
      if (e.toString().contains('Forbidden') || e.toString().contains('403')) {
        if (mounted) setState(() => _isPremiumRequired = true);
      } else {
        if (mounted) setState(() => _coachError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loadingCoach = false);
    }
  }

  Future<void> _moveToApplied() => _doMoveStage(
        'Applied',
        timelineLabel: 'Moved to Applied',
        timelineDetail: '',
        timelineType: 'stage_change',
      );

  Future<void> _showOfferDialog() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Offer received 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optionally record the offer details:'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                hintText: 'e.g. €65,000 + equity',
                labelText: 'Offer amount / details',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save & Move to Offer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _doMoveStage(
      'Offer',
      extra: ctrl.text.trim().isNotEmpty ? {'offer_amount': ctrl.text.trim()} : null,
      timelineLabel: 'Offer received',
      timelineDetail: ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : '',
      timelineType: 'offer_received',
    );
  }

  Future<void> _showRejectedDialog() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Rejected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optionally record feedback from the company:'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Lack of seniority for the role',
                labelText: 'Company feedback',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark as Rejected', style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _doMoveStage(
      'Rejected',
      extra: ctrl.text.trim().isNotEmpty ? {'rejection_feedback': ctrl.text.trim()} : null,
      timelineLabel: 'Rejected',
      timelineDetail: ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : '',
      timelineType: 'rejected',
    );
  }

  Future<void> _doMoveStage(
    String stage, {
    Map<String, dynamic>? extra,
    required String timelineLabel,
    required String timelineDetail,
    required String timelineType,
  }) async {
    if (_moving) return;
    setState(() => _moving = true);
    try {
      final pipeline = Provider.of<PipelineProvider>(context, listen: false);
      final job = await pipeline.syncJobIfNeeded(widget.job);

      final updated = await PipelineService()
          .moveToStage(job.id, stage, extra: extra);

      final normalizedRequestedStage = stage.trim().toLowerCase();
      final normalizedResponseStage = updated.stage.trim().toLowerCase();
      final resolvedUpdated = normalizedResponseStage == normalizedRequestedStage
          ? updated
          : updated.copyWith(stage: stage);

      final hasEvent = resolvedUpdated.timeline.any((e) => e.type == timelineType);
      final finalJob = hasEvent
          ? resolvedUpdated
          : resolvedUpdated.copyWith(
              timeline: [
                ...job.timeline,
                TimelineEvent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: timelineType,
                  label: timelineLabel,
                  detail: timelineDetail,
                  createdAt: DateTime.now(),
                ),
              ],
            );

      widget.onJobUpdated(finalJob);
      await pipeline.refresh();
      PipelineService.clearCachedCoach(finalJob.id, job.stage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBg    = isDark ? const Color(0xFF0D2B1E) : const Color(0xFFE1F5EE);
    final avatarText  = isDark ? const Color(0xFF5DCAA5) : const Color(0xFF0F6E56);
    final titleColor  = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final bubbleBg    = isDark ? const Color(0xFF222535) : const Color(0xFFF5F5F5);
    final bubbleText  = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final job = widget.job;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: avatarText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hirefy Coach',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    '${job.jobTitle} at ${job.companyName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Coach bubble
          Container(
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _coachBubbleLabel(job.stage),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                if (_loadingCoach)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1D9E75),
                        ),
                      ),
                    ),
                  )
                else if (_isPremiumRequired)
                  _CoachPremiumBanner(onUpgradeTapped: _handleUpgrade)
                else if (_coachError != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Could not load suggestion.',
                          style: TextStyle(
                              fontSize: 12,
                              color: bubbleText.withValues(alpha: 0.5)),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadCoachContent,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Retry',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF1D9E75))),
                      ),
                    ],
                  )
                else
                  Text(
                    _coachContent ?? _coachFallback(job),
                    style: TextStyle(
                      fontSize: 12,
                      color: bubbleText,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

            // Primary action button — label adapts to stage
          if (job.stage == 'Wishlist') ...
            [
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _moving ? null : _moveToApplied,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _moving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Mark as Applied',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
            ]
          else if (job.stage != 'Rejected') ...
            [
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FollowUpCoachSheet(
                      job: widget.job,
                      onJobUpdated: widget.onJobUpdated,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _primaryButtonLabel(job.stage),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          const SizedBox(height: 8),
          if (job.stage == 'Applied' || job.stage == 'Interview')
            _SecondaryButton(
            label: 'Log interview scheduled',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => InterviewScheduleSheet(
                job: widget.job,
                onJobUpdated: widget.onJobUpdated,
              ),
            ),
          ),
          if (job.stage == 'Interview') ...[
            const SizedBox(height: 8),
            _SecondaryButton(
              label: 'I received an offer 🎉',
              onTap: _moving ? () {} : _showOfferDialog,
            ),
            const SizedBox(height: 8),
            _SecondaryButton(
              label: 'Mark as Rejected',
              onTap: _moving ? () {} : _showRejectedDialog,
              textColor: const Color(0xFFE57373),
            ),
          ],
          if (job.stage == 'Offer') ...[
            const SizedBox(height: 8),
            _SecondaryButton(
              label: 'Accept offer ✓',
              onTap: _moving ? () {} : () => _doMoveStage(
                'Accepted',
                timelineLabel: 'Offer accepted',
                timelineDetail: '',
                timelineType: 'offer_accepted',
              ),
            ),
            const SizedBox(height: 8),
            _SecondaryButton(
              label: 'Decline offer',
              onTap: _moving ? () {} : _showRejectedDialog,
              textColor: const Color(0xFFE57373),
            ),
          ],

          // Timeline
          const SizedBox(height: 18),
          const Text(
            'Timeline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 10),
          if (job.timeline.isEmpty) ...[  
            const _TimelineItem(
              dotColor: Color(0xFF1D9E75),
              title: 'Applied',
              subtitle: '',
              showLine: true,
            ),
            const _TimelineItem(
              dotColor: Color(0xFFBDBDBD),
              title: 'Awaiting response...',
              titleColor: Color(0xFFAAAAAA),
              subtitle: '',
              showLine: false,
            ),
          ] else
            for (int i = 0; i < job.timeline.length; i++)
              _TimelineItem(
                dotColor: const Color(0xFF1D9E75),
                title: job.timeline[i].label,
                subtitle: job.timeline[i].detail,
                showLine: i < job.timeline.length - 1,
              ),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    final result = await RevenueCatUI.presentPaywall();
    if (!mounted) return;
    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await Provider.of<SubscriptionProvider>(context, listen: false)
          .loadSubscription(force: true);
      if (!mounted) return;
      final isPro =
          Provider.of<SubscriptionProvider>(context, listen: false).isPro;
      if (isPro) {
        setState(() {
          _isPremiumRequired = false;
          _coachContent = null;
          _coachError = null;
        });
        _loadCoachContent();
      }
    }
  }

  String _coachBubbleLabel(String stage) {
    switch (stage) {
      case 'Interview': return 'INTERVIEW PREPARATION';
      case 'Offer':     return 'OFFER INSIGHTS';
      case 'Rejected':  return 'FEEDBACK REQUEST';
      default:          return 'SUGGESTED NEXT ACTION';
    }
  }

  String _primaryButtonLabel(String stage) {
    switch (stage) {
      case 'Interview': return 'Get interview prep with AI →';
      case 'Offer':     return 'Get offer insights with AI →';
      default:          return 'Write follow-up with AI →';
    }
  }

  String _coachFallback(JobApplication job) {
    switch (job.stage) {
      case 'Interview':
        return 'You have an interview coming up for ${job.jobTitle} at ${job.companyName}. Tap below to get a personalised preparation guide.';
      case 'Offer':
        return 'You received an offer for ${job.jobTitle} at ${job.companyName}. Tap below for negotiation tips and relevant insights.';
      case 'Rejected':
        return 'Your application for ${job.jobTitle} at ${job.companyName} was not successful this time. Consider requesting feedback.';
      default:
        return 'You applied $_daysSinceApplied days ago. It might be a good time to send a polite follow-up to the recruiter.';
    }
  }
}

// ─── Secondary button ─────────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  const _SecondaryButton({required this.label, required this.onTap, this.textColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2D3144) : const Color(0xFFDDDDDD);
    final defaultTextColor = isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444);
    final resolvedTextColor = textColor ?? defaultTextColor;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: resolvedTextColor,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: textColor != null ? textColor!.withOpacity(0.4) : borderColor, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}

// ─── Timeline item ────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final Color dotColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final bool showLine;

  const _TimelineItem({
    required this.dotColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTitle = titleColor ?? (isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A));
    final lineColor = isDark ? const Color(0xFF2D3144) : const Color(0xFFE0E0E0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (showLine)
              Container(
                width: 1,
                height: 28,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: resolvedTitle,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Tab 2: ATS Match ─────────────────────────────────────────────────────────

class _AtsMatchTab extends StatefulWidget {
  final JobApplication job;

  const _AtsMatchTab({required this.job});

  @override
  State<_AtsMatchTab> createState() => _AtsMatchTabState();
}

class _AtsMatchTabState extends State<_AtsMatchTab> {
  Resume? _resume;
  bool _loading = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.job.resumeId != null) {
      _loadResume();
    }
  }

  Future<void> _loadResume() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final resume = await Provider.of<ResumeProvider>(context, listen: false)
          .getResumeById(widget.job.resumeId!, type: 'optimized');
      if (mounted) {
        setState(() => _resume = resume);
        // Sync the ATS score back to the provider so the kanban card reflects it.
        // This restores scores that were lost (e.g. stored as 0 from an old API response).
        final score = resume?.score;
        if (score != null && score > 0 && widget.job.id.isNotEmpty) {
          Provider.of<PipelineProvider>(context, listen: false)
              .updateJobAtsScore(widget.job.id, score.toInt());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _scoreLabel(double score) {
    if (score >= 80) return 'Strong match';
    if (score >= 60) return 'Good match';
    return 'Needs improvement';
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Future<void> _downloadPdf() async {
    if (_resume == null) return;
    setState(() => _downloading = true);
    try {
      await PdfService().previewPdf(_resume!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg    = isDark ? const Color(0xFF222535) : const Color(0xFFF5F5F5);
    final titleClr  = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final trackClr  = isDark ? const Color(0xFF2D3144) : const Color(0xFFE0E0E0);
    final docBg     = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final docBorder = isDark ? const Color(0xFF2D3144) : const Color(0xFFE0E0E0);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasResume  = _resume != null;
    final score      = hasResume && _resume!.score != null
        ? _resume!.score!
        : widget.job.atsScore.toDouble();
    final scoreColor   = _scoreColor(score);
    final suggestions  = _resume?.suggestions ?? [];
    final missingKws   = _resume?.missingRequirements ?? [];
    final hasMissing   = missingKws.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Resume used — topo em destaque ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: docBg,
                    border: Border.all(color: docBorder, width: 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    hasResume
                        ? Icons.auto_awesome_rounded
                        : Icons.description,
                    size: 16,
                    color: hasResume ? scoreColor : const Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume used',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.job.resumeVersion,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleClr,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_resume != null) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ResumeManualForm(initialResume: _resume),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1D9E75),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Edit',
                        style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  _downloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _downloadPdf,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1D9E75),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Download',
                              style: TextStyle(fontSize: 12)),
                        ),
                ],
              ],
            ),
          ),

          // ── Score ring card ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(score, trackClr, scoreColor),
                    child: Center(
                      child: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scoreLabel(score),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: titleClr,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasMissing
                            ? '${missingKws.length} missing keyword${missingKws.length == 1 ? '' : 's'} lowering your score.'
                            : hasResume
                                ? 'Great! No critical keywords missing.'
                                : 'Attach an optimized resume to see details.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Improvements applied (suggestions) ──────────────────────────
          if (suggestions.isNotEmpty) ...[
            const Text(
              'Improvements applied',
              style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_outline_rounded,
                          size: 13, color: scoreColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Missing keywords ─────────────────────────────────────────────
          if (hasMissing) ...[
            const Text(
              'Missing keywords',
              style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final kw in missingKws)
                  _KeywordChip(label: kw, matched: false),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// ─── Score ring painter ───────────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color trackColor;
  final Color fillColor;

  const _ScoreRingPainter(this.score, this.trackColor, this.fillColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 5) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    paint.color = fillColor;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * score / 100,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.score != score || old.trackColor != trackColor || old.fillColor != fillColor;
}

// ─── Keyword chip ─────────────────────────────────────────────────────────────

class _KeywordChip extends StatelessWidget {
  final String label;
  final bool matched;

  const _KeywordChip({required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = matched
        ? (isDark ? const Color(0xFF0D2B1E) : const Color(0xFFE1F5EE))
        : (isDark ? const Color(0xFF2D1010) : const Color(0xFFFCEBEB));
    final fg = matched
        ? (isDark ? const Color(0xFF5DCAA5) : const Color(0xFF0F6E56))
        : (isDark ? const Color(0xFFE57373) : const Color(0xFFA32D2D));
    final borderClr = isDark ? const Color(0xFF8B3232) : const Color(0xFFF09595);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: matched ? null : Border.all(color: borderClr, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg),
      ),
    );
  }
}

// ─── Tab 3: Contacts ─────────────────────────────────────────────────────────

class _ContactsTab extends StatefulWidget {
  final JobApplication job;

  const _ContactsTab({required this.job});

  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  final _service = PipelineService();
  List<Contact>? _contacts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.fetchContacts(widget.job.id);
      if (mounted) setState(() { _contacts = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final linkedinCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add contact',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _AddField(controller: nameCtrl, label: 'Name *'),
              const SizedBox(height: 10),
              _AddField(controller: roleCtrl, label: 'Role'),
              const SizedBox(height: 10),
              _AddField(controller: emailCtrl, label: 'Email',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _LinkedInField(controller: linkedinCtrl, isDark: isDark),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        final contact = await _service.addContact(
          widget.job.id,
          name: nameCtrl.text.trim(),
          role: roleCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          linkedinUrl: linkedinCtrl.text.trim().isEmpty
              ? ''
              : 'https://linkedin.com/in/${linkedinCtrl.text.trim().replaceAll('@', '')}' ,
        );
        if (mounted) setState(() => _contacts = [...(_contacts ?? []), contact]);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add contact')),
          );
        }
      }
    }
  }

  Future<void> _delete(Contact contact) async {
    setState(() => _contacts = _contacts?.where((c) => c.id != contact.id).toList());
    try {
      await _service.deleteContact(widget.job.id, contact.id);
    } catch (_) {
      if (mounted) {
        setState(() => _contacts = [...(_contacts ?? []), contact]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove contact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBorder =
        isDark ? const Color(0xFF2D3144) : const Color(0xFFDDDDDD);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contacts at ${widget.job.companyName}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 10),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Could not load contacts',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ),
            )
          else if (_contacts!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No contacts yet. Add your first one.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ),
            )
          else
            ...(_contacts!.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ContactRow(
                    contact: c,
                    onDelete: () => _delete(c),
                  ),
                ))),

          const SizedBox(height: 4),
          GestureDetector(
            onTap: _showAddDialog,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: btnBorder, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 14, color: Color(0xFF888888)),
                  SizedBox(width: 4),
                  Text('+ Add contact',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper text field for Add dialog ────────────────────────────────────────

class _AddField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _AddField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFF2D3144)
                  : const Color(0xFFDDDDDD)),
        ),
      ),
    );
  }
}

// ─── Contact row ──────────────────────────────────────────────────────────────

class _LinkedInField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _LinkedInField({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? const Color(0xFF2D3144) : const Color(0xFFDDDDDD);
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final prefixBg =
        isDark ? const Color(0xFF2D3144) : const Color(0xFFF5F5F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LinkedIn',
            style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: prefixBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
                child: const Text('linkedin.com/in/',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: const InputDecoration(
                    hintText: 'username',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Color(0xFFAAAAAA)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final Contact contact;
  final VoidCallback onDelete;

  const _ContactRow({required this.contact, required this.onDelete});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Deterministic color pair from name
  static const _palettes = [
    [Color(0xFFE6F1FB), Color(0xFF185FA5)],
    [Color(0xFFEEEDFE), Color(0xFF534AB7)],
    [Color(0xFFE6FBF4), Color(0xFF1D9E75)],
    [Color(0xFFFFF3E0), Color(0xFFE65100)],
    [Color(0xFFFCE4EC), Color(0xFFC2185B)],
  ];

  List<Color> _colors(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _palettes.length;
    return _palettes[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colors(contact.name);
    final initials = _initials(contact.name);

    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => _showDetail(context, isDark, colors, initials),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: colors[0], shape: BoxShape.circle),
                child: Text(initials,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors[1])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFF1A1A1A),
                        )),
                    if (contact.role.isNotEmpty)
                      Text(contact.role,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: Color(0xFFAAAAAA)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, bool isDark, List<Color> colors,
      String initials) {
    final bgColor = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final labelColor = const Color(0xFF888888);
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final dividerColor =
        isDark ? const Color(0xFF2D3144) : const Color(0xFFEEEEEE);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: colors[0], shape: BoxShape.circle),
                    child: Text(initials,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors[1])),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        if (contact.role.isNotEmpty)
                          Text(contact.role,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: dividerColor, height: 1),
              const SizedBox(height: 16),

              // Fields
              if (contact.email.isNotEmpty) ...[
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: contact.email,
                  labelColor: labelColor,
                  textColor: textColor,
                  onTap: () => launchUrl(
                      Uri.parse('mailto:${contact.email}')),
                ),
                const SizedBox(height: 12),
              ],
              if (contact.linkedinUrl.isNotEmpty) ...[
                _DetailRow(
                  icon: Icons.link,
                  label: 'LinkedIn',
                  value: contact.linkedinUrl,
                  labelColor: labelColor,
                  textColor: const Color(0xFF1D9E75),
                  onTap: () => launchUrl(Uri.parse(contact.linkedinUrl),
                      mode: LaunchMode.externalApplication),
                ),
                const SizedBox(height: 12),
              ],
              if (contact.notes.isNotEmpty) ...[
                _DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: contact.notes,
                  labelColor: labelColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 12),
              ],
              if (contact.email.isEmpty &&
                  contact.linkedinUrl.isEmpty &&
                  contact.notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No additional details.',
                      style: TextStyle(
                          fontSize: 12, color: labelColor)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Detail row inside contact bottom sheet ───────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: labelColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: labelColor)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(fontSize: 13, color: textColor)),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: labelColor),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: row);
    }
    return row;
  }
}

// ─── Coach Premium Banner ─────────────────────────────────────────────────────

class _CoachPremiumBanner extends StatelessWidget {
  final VoidCallback? onUpgradeTapped;

  const _CoachPremiumBanner({this.onUpgradeTapped});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              'Premium feature',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'AI Coach suggestions are available on the Premium plan. Upgrade to get personalised tips, follow-up scripts and interview prep for every application.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onUpgradeTapped ?? () => RevenueCatUI.presentPaywall(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upgrade to Premium',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}
