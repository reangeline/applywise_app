import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/resume.dart';
import '../providers/resume_provider.dart';
import '../screens/resume/resume_manual_form.dart';
import '../screens/resume/resume_pdf_upload_screen.dart';

// ─── ResumeSelectorStep ───────────────────────────────────────────────────────

class ResumeSelectorStep extends StatefulWidget {
  final String? selectedResumeId;
  final ValueChanged<String?> onResumeSelected;

  const ResumeSelectorStep({
    super.key,
    required this.selectedResumeId,
    required this.onResumeSelected,
  });

  @override
  State<ResumeSelectorStep> createState() => _ResumeSelectorStepState();
}

class _ResumeSelectorStepState extends State<ResumeSelectorStep>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ResumeProvider>(context, listen: false).loadResumes();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Resume> _manualResumes(List<Resume> all) =>
      all.where((r) => r.type == 'manual' && _hasContent(r)).toList();

  List<Resume> _optimizedResumes(List<Resume> all) =>
      all.where((r) => r.type == 'optimized' && _hasContent(r)).toList();

  bool _hasContent(Resume r) {
    if (r.type == 'manual') {
      final p = r.personal;
      if (p == null) return false;
      final hasPersonal = p.fullName.isNotEmpty || p.email.isNotEmpty;
      final hasEntries = (r.experiences?.isNotEmpty == true) ||
          (r.education?.isNotEmpty == true);
      return hasPersonal || hasEntries;
    }
    // optimized: must have actual content
    return (r.optimizedText?.isNotEmpty == true) ||
        (r.suggestions?.isNotEmpty == true) ||
        r.score != null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resumeProvider = Provider.of<ResumeProvider>(context);
    final manual = _manualResumes(resumeProvider.resumes);
    final optimized = _optimizedResumes(resumeProvider.resumes);
    final currentList = _tabController.index == 0 ? manual : optimized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tab bar ─────────────────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          indicatorColor: cs.primary,
          dividerColor: cs.outline.withValues(alpha: 0.3),
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Manual'),
            Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'AI Optimized'),
          ],
        ),
        const SizedBox(height: 12),

        // ── Resume list ──────────────────────────────────────────────────────
        if (resumeProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (currentList.isEmpty)
          _EmptyState(isManual: _tabController.index == 0)
        else
          ...currentList.map(
            (r) => _ResumeListItem(
              resume: r,
              isSelected: widget.selectedResumeId == r.id,
              onTap: () => widget.onResumeSelected(r.id),
            ),
          ),

        const SizedBox(height: 16),

        // ── "or" separator ───────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Divider(color: cs.outline.withValues(alpha: 0.35), height: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            Expanded(
              child: Divider(color: cs.outline.withValues(alpha: 0.35), height: 1),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Create options ──────────────────────────────────────────────────
        _CreateOptionCard(
          icon: Icons.edit_note,
          iconColor: cs.primary,
          iconBg: cs.primary.withValues(alpha: 0.15),
          title: 'Fill Manually',
          subtitle: 'Add your information step by step.',
          onTap: () async {
            final navigator = Navigator.of(context);
            final provider =
                Provider.of<ResumeProvider>(context, listen: false);
            await navigator.push(
              MaterialPageRoute(builder: (_) => const ResumeManualForm()),
            );
            if (!mounted) return;
            await provider.loadResumes();
            if (!mounted) return;
            final updated = _manualResumes(provider.resumes);
            if (updated.isNotEmpty) {
              updated.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              widget.onResumeSelected(updated.first.id);
            }
          },
        ),
        const SizedBox(height: 8),
        _CreateOptionCard(
          icon: Icons.picture_as_pdf,
          iconColor: cs.tertiary,
          iconBg: cs.tertiary.withValues(alpha: 0.15),
          title: 'Import PDF',
          subtitle: 'Upload a PDF and let AI pre-fill your resume.',
          onTap: () async {
            final navigator = Navigator.of(context);
            final provider =
                Provider.of<ResumeProvider>(context, listen: false);
            await navigator.push(
              MaterialPageRoute(builder: (_) => const ResumePdfUploadScreen()),
            );
            if (!mounted) return;
            await provider.loadResumes();
            if (!mounted) return;
            final all = provider.resumes;
            if (all.isNotEmpty) {
              final sorted = [...all]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              widget.onResumeSelected(sorted.first.id);
            }
          },
        ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isManual;
  const _EmptyState({required this.isManual});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          isManual ? 'No manual resumes yet.' : 'No AI optimized resumes yet.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

// ─── Resume list item ─────────────────────────────────────────────────────────

class _ResumeListItem extends StatelessWidget {
  final Resume resume;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResumeListItem({
    required this.resume,
    required this.isSelected,
    required this.onTap,
  });

  String get _displayName {
    if (resume.type == 'manual') {
      return resume.nickname ??
          resume.personal?.fullName.let((n) => n.isNotEmpty ? n : null) ??
          'Manual Resume';
    }
    if (resume.targetRole != null && resume.targetRole!.isNotEmpty) {
      if (resume.targetCompany != null && resume.targetCompany!.isNotEmpty) {
        return '${resume.targetRole} @ ${resume.targetCompany}';
      }
      return resume.targetRole!;
    }
    return resume.personal?.currentRole ?? resume.nickname ?? 'AI Optimized';
  }

  String get _typeLabel =>
      resume.type == 'manual' ? 'Manual Resume' : 'AI Optimized';

  IconData get _typeIcon =>
      resume.type == 'manual' ? Icons.edit_note : Icons.auto_awesome;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr =
        DateFormat.yMMMd().format(resume.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.08)
              : cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(_typeIcon, size: 12, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        _typeLabel,
                        style: TextStyle(fontSize: 11, color: cs.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Created $dateStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(Icons.check_circle, color: cs.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Create option card ───────────────────────────────────────────────────────

class _CreateOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Extension helper ─────────────────────────────────────────────────────────

extension _StringLet on String {
  T let<T>(T Function(String) block) => block(this);
}
