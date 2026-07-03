import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/job_application.dart';
import '../models/resume.dart';
import '../providers/resume_provider.dart';
import 'resume_selector_step.dart';

// ─── AddJobResult ─────────────────────────────────────────────────────────────

/// Returned by [AddJobBottomSheet] via Navigator.pop.
class AddJobResult {
  final JobApplication job;
  final bool navigateToOptimize;
  final String? resumeId;
  final String? jobDescriptionOrUrl;
  final String? company;

  const AddJobResult({
    required this.job,
    required this.navigateToOptimize,
    this.resumeId,
    this.jobDescriptionOrUrl,
    this.company,
  });
}

// ─── Color palette for auto-generated company logos ─────────────────────────

const _logoPalette = [
  (Color(0xFFE6F1FB), Color(0xFF185FA5)),
  (Color(0xFFFBEAF0), Color(0xFF993556)),
  (Color(0xFFEAF3DE), Color(0xFF3B6D11)),
  (Color(0xFFFAEEDA), Color(0xFF854F0B)),
  (Color(0xFFE1F5EE), Color(0xFF085041)),
  (Color(0xFFEEEDFE), Color(0xFF534AB7)),
];

const _stages = ['Wishlist', 'Applied', 'Interview', 'Offer', 'Rejected'];

// ─── AddJobBottomSheet ────────────────────────────────────────────────────────

class AddJobBottomSheet extends StatefulWidget {
  const AddJobBottomSheet({super.key});

  @override
  State<AddJobBottomSheet> createState() => _AddJobBottomSheetState();
}

class _AddJobBottomSheetState extends State<AddJobBottomSheet> {
  // ── Step control ────────────────────────────────────────────────────────────
  int _step = 1;

  // ── Step 1 ──────────────────────────────────────────────────────────────────
  String _selectedMethod = 'url'; // 'url' | 'desc' | 'manual'

  // ── Step 2 – AI input ────────────────────────────────────────────────────────
  final _inputCtrl = TextEditingController();
  bool _isParsing = false;
  bool _analysisCancelled = false;
  double _parsingProgress = 0.0;
  String _parsingLabel = '';

  // Fake parsed data (populated after analysis)
  final String _parsedCompany = 'Vercel';
  final String _parsedRole = 'Senior Mobile Engineer';
  final String _parsedLocation = 'Remote · US';
  final int _parsedAtsScore = 83;
  final List<String> _missingKeywords = ['Turborepo', 'Edge Runtime'];

  // ── Step 2 – manual input ────────────────────────────────────────────────────
  final _manualCompanyCtrl = TextEditingController();
  final _manualRoleCtrl = TextEditingController();
  final _manualLocationCtrl = TextEditingController();
  String _manualStage = 'Applied';

  // ── Step 3 ──────────────────────────────────────────────────────────────────
  String? _selectedResumeId;

  // ── Step 4 ──────────────────────────────────────────────────────────────────
  String _selectedStage = 'Applied';

  // ── Step 5 ──────────────────────────────────────────────────────────────────
  final _optimizerJobDescCtrl = TextEditingController();
  String? _optimizedResumeId;
  bool _isOptimizing = false;
  bool _optimizationDone = false;
  String? _optimizationError;

  // ── Derived helpers ──────────────────────────────────────────────────────────
  bool get _isAiParsed => _selectedMethod != 'manual';

  String get _effectiveCompany =>
      _isAiParsed ? _parsedCompany : _manualCompanyCtrl.text.trim();

  String get _effectiveRole =>
      _isAiParsed ? _parsedRole : _manualRoleCtrl.text.trim();

  String get _effectiveLocation =>
      _isAiParsed ? _parsedLocation : _manualLocationCtrl.text.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ResumeProvider>(context, listen: false).loadResumes();
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _manualCompanyCtrl.dispose();
    _manualRoleCtrl.dispose();
    _manualLocationCtrl.dispose();
    _optimizerJobDescCtrl.dispose();
    super.dispose();
  }

  // ─── Back navigation ─────────────────────────────────────────────────────────

  void _goBack() {
    if (_step == 2 && _isParsing) {
      _analysisCancelled = true;
    }
    setState(() {
      if (_step == 2 && _isParsing) {
        _isParsing = false;
        _parsingProgress = 0;
        _parsingLabel = '';
      }
      if (_step == 5) {
        _isOptimizing = false;
        _optimizationDone = false;
        _optimizationError = null;
        _optimizedResumeId = null;
      }
      _step--;
    });
  }

  // ─── Fake analysis ────────────────────────────────────────────────────────────

  Future<void> _runAnalysis() async {
    _analysisCancelled = false;
    setState(() {
      _isParsing = true;
      _parsingProgress = 0.0;
      _parsingLabel = 'Reading job posting...';
    });

    const timeline = [
      (500, 0.30, 'Reading job posting...'),
      (500, 0.60, 'Extracting role and company...'),
      (500, 0.85, 'Calculating ATS match...'),
      (400, 1.00, 'Done!'),
    ];

    for (final (ms, progress, label) in timeline) {
      await Future.delayed(Duration(milliseconds: ms));
      if (!mounted || _analysisCancelled) return;
      setState(() {
        _parsingProgress = progress;
        _parsingLabel = label;
      });
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || _analysisCancelled) return;

    setState(() {
      _isParsing = false;
      _step = 3;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Progress dots
          _ProgressDots(step: _step),
          const SizedBox(height: 14),

          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 230),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildCurrentStep(cs),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme cs) {
    switch (_step) {
      case 1:
        return _buildStep1(cs);
      case 2:
        return _buildStep2(cs);
      case 3:
        return _buildStep3(cs);
      case 4:
        return _buildStep4(cs);
      case 5:
        return _buildStep5(cs);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1 – Choose method ───────────────────────────────────────────────────

  Widget _buildStep1(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a job',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How do you want to add this job?',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),

        // Method cards
        _MethodCard(
          icon: Icons.link_rounded,
          title: 'Paste job URL',
          description:
              'We extract everything automatically from LinkedIn, Indeed, Greenhouse etc.',
          badge: const _AiBadge(),
          isSelected: _selectedMethod == 'url',
          onTap: () => setState(() => _selectedMethod = 'url'),
        ),
        const SizedBox(height: 10),
        _MethodCard(
          icon: Icons.content_paste_rounded,
          title: 'Paste job description',
          description:
              'Copy the full description text and we analyze it for you.',
          badge: const _AiBadge(),
          isSelected: _selectedMethod == 'desc',
          onTap: () => setState(() => _selectedMethod = 'desc'),
        ),
        const SizedBox(height: 10),
        _MethodCard(
          icon: Icons.edit_outlined,
          title: 'Fill in manually',
          description: 'Enter company, role, and stage yourself.',
          isSelected: _selectedMethod == 'manual',
          onTap: () => setState(() => _selectedMethod = 'manual'),
        ),
        const SizedBox(height: 24),

        _PrimaryButton(
          label: 'Continue \u2192',
          onTap: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  // ─── Step 2 – Input ───────────────────────────────────────────────────────────

  Widget _buildStep2(ColorScheme cs) {
    return _selectedMethod == 'manual'
        ? _buildManualInput(cs)
        : _buildAiInput(cs);
  }

  Widget _buildAiInput(ColorScheme cs) {
    final isUrl = _selectedMethod == 'url';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _StepHeader(
          title: isUrl ? 'Paste the URL' : 'Paste description',
          onBack: _goBack,
        ),
        const SizedBox(height: 20),

        // Input field
        TextField(
          controller: _inputCtrl,
          maxLines: 5,
          minLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: isUrl
                ? 'https://boards.greenhouse.io/...'
                : 'Paste the full job description here...',
            hintStyle:
                TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Progress bar + label
        if (_isParsing) ...[
          LinearProgressIndicator(
            value: _parsingProgress,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 6),
          Text(
            _parsingLabel,
            style: TextStyle(fontSize: 11, color: cs.primary),
          ),
          const SizedBox(height: 14),
        ] else
          const SizedBox(height: 14),

        _PrimaryButton(
          label: 'Analyze with AI \u2192',
          onTap: _isParsing ? null : _runAnalysis,
        ),
      ],
    );
  }

  Widget _buildManualInput(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(title: 'Enter job details', onBack: _goBack),
        const SizedBox(height: 20),

        // Company + Role row
        Row(
          children: [
            Expanded(
              child: _OutlineTextField(
                controller: _manualCompanyCtrl,
                labelText: 'Company',
                hintText: 'e.g. Stripe',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineTextField(
                controller: _manualRoleCtrl,
                labelText: 'Role',
                hintText: 'e.g. iOS Engineer',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Location
        _OutlineTextField(
          controller: _manualLocationCtrl,
          labelText: 'Location',
          hintText: 'e.g. Remote · US',
        ),
        const SizedBox(height: 12),

        // Stage dropdown
        DropdownButtonFormField<String>(
          initialValue: _manualStage,
          decoration: InputDecoration(
            labelText: 'Stage',
            floatingLabelStyle: TextStyle(color: cs.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: _stages
              .map(
                (s) => DropdownMenuItem(value: s, child: Text(s)),
              )
              .toList(),
          onChanged: (v) => setState(() => _manualStage = v ?? 'Applied'),
        ),
        const SizedBox(height: 24),

        _PrimaryButton(
          label: 'Next \u2192',
          onTap: () => setState(() {
            _selectedStage = _manualStage;
            _step = 3;
          }),
        ),
      ],
    );
  }

  // ─── Step 3 – Select resume ───────────────────────────────────────────────────

  Widget _buildStep3(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(title: 'Select a resume', onBack: _goBack),
        const SizedBox(height: 16),

        ResumeSelectorStep(
          selectedResumeId: _selectedResumeId,
          onResumeSelected: (id) => setState(() => _selectedResumeId = id),
        ),
        const SizedBox(height: 20),

        _PrimaryButton(
          label: 'Next \u2192',
          onTap: _selectedResumeId != null
              ? () => setState(() => _step = 4)
              : null,
        ),
      ],
    );
  }

  // ─── Step 4 – Review & confirm ────────────────────────────────────────────────

  Widget _buildStep4(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(title: 'Review & confirm', onBack: _goBack),
        const SizedBox(height: 20),

        // ATS score ring (AI only)
        if (_isAiParsed)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _AtsRingPainter(
                      score: _parsedAtsScore.toDouble(),
                      trackColor: cs.onSurface.withValues(alpha: 0.1),
                      arcColor: cs.primary,
                    ),
                    child: Center(
                      child: Text(
                        '$_parsedAtsScore%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
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
                        'Good match',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_missingKeywords.length} keywords missing from your resume.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Field summary
        _FieldRow(
          label: 'Company',
          value: _effectiveCompany.isEmpty ? '—' : _effectiveCompany,
          aiFilled: _isAiParsed,
        ),
        _FieldRow(
          label: 'Role',
          value: _effectiveRole.isEmpty ? '—' : _effectiveRole,
          aiFilled: _isAiParsed,
        ),
        if (_effectiveLocation.isNotEmpty)
          _FieldRow(
            label: 'Location',
            value: _effectiveLocation,
            aiFilled: _isAiParsed,
          ),

        // Missing keywords (AI only)
        if (_isAiParsed && _missingKeywords.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Keywords missing from selected resume',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _missingKeywords
                .map((kw) => _KeywordChip(label: kw))
                .toList(),
          ),
          const SizedBox(height: 14),
        ] else
          const SizedBox(height: 4),

        // Stage label
        Text(
          'Stage',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),

        // Stage pills
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _stages.map((s) {
              final isActive = s == _selectedStage;
              return GestureDetector(
                onTap: () => setState(() => _selectedStage = s),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: isActive
                        ? null
                        : Border.all(
                            color: cs.outline.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? cs.onPrimary
                          : cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Add & Optimize → Step 5
        _PrimaryButton(
          label: 'Optimize & Add to Pipeline →',
          onTap: () {
            if (_optimizerJobDescCtrl.text.isEmpty &&
                _inputCtrl.text.isNotEmpty) {
              _optimizerJobDescCtrl.text = _inputCtrl.text;
            }
            setState(() => _step = 5);
          },
        ),
        const SizedBox(height: 8),

        // Add without optimizing
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _submitWithoutOptimize,
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(
                  color: cs.outline.withValues(alpha: 0.5), width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Add without optimizing',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Submit helpers ───────────────────────────────────────────────────────────

  /// Called from Step 5 — uses the optimized/selected resume.
  void _submitFinal() => _doSubmit(useOptimized: true);

  /// Skips optimization completely; uses the base resume from Step 3.
  void _submitWithoutOptimize() => _doSubmit(useOptimized: false);

  void _doSubmit({required bool useOptimized}) {
    final company = _effectiveCompany.isEmpty ? 'Company' : _effectiveCompany;
    final role = _effectiveRole.isEmpty ? 'Role' : _effectiveRole;
    final today = DateFormat.MMMd().format(DateTime.now());

    final (logoBg, logoText) =
        _logoPalette[company.hashCode.abs() % _logoPalette.length];

    final resumeProvider =
        Provider.of<ResumeProvider>(context, listen: false);
    final finalResumeId =
        (useOptimized ? _optimizedResumeId : null) ?? _selectedResumeId;

    final selectedResume = finalResumeId != null
        ? resumeProvider.resumes
            .where((r) => r.id == finalResumeId)
            .firstOrNull
        : null;

    final resumeLabel = selectedResume != null
        ? (selectedResume.nickname ??
            selectedResume.personal?.fullName
                .let((n) => n.isNotEmpty ? n : null) ??
            (selectedResume.type == 'optimized' ? 'AI Opt.' : 'My Resume'))
        : '';

    final job = JobApplication(
      companyInitials: _companyInitials(company),
      logoBackground: logoBg,
      logoTextColor: logoText,
      jobTitle: role,
      companyName: company,
      dateApplied: today,
      resumeVersion: resumeLabel,
      atsScore: _isAiParsed ? _parsedAtsScore : 0,
      stage: _selectedStage,
      resumeId: finalResumeId,
      location: _effectiveLocation.isEmpty ? null : _effectiveLocation,
    );

    final result = AddJobResult(
      job: job,
      navigateToOptimize: false,
      resumeId: finalResumeId,
      jobDescriptionOrUrl: _inputCtrl.text.trim().isEmpty
          ? null
          : _inputCtrl.text.trim(),
      company: company,
    );

    Navigator.of(context).pop(result);
  }

  // ─── Optimization ─────────────────────────────────────────────────────────────

  Future<void> _runOptimization() async {
    if (_selectedResumeId == null) return;
    final provider = Provider.of<ResumeProvider>(context, listen: false);
    setState(() {
      _isOptimizing = true;
      _optimizationError = null;
      _optimizationDone = false;
    });
    try {
      final result = await provider.optimizeResume(
        resumeId: _selectedResumeId!,
        jobDescription: _optimizerJobDescCtrl.text,
        targetCompany: _effectiveCompany.isEmpty ? null : _effectiveCompany,
        targetRole: _effectiveRole.isEmpty ? null : _effectiveRole,
      );
      if (!mounted) return;
      setState(() {
        _isOptimizing = false;
        _optimizationDone = true;
        _optimizedResumeId = result?.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOptimizing = false;
        _optimizationError = e.toString();
      });
    }
  }

  // ─── Step 5 – Optimize resume ─────────────────────────────────────────────────

  Widget _buildStep5(ColorScheme cs) {
    final provider = Provider.of<ResumeProvider>(context);
    final optimizedResumes =
        provider.resumes.where((r) => r.type == 'optimized').toList();
    final canAdd = _optimizedResumeId != null || _optimizationDone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(title: 'Optimize resume', onBack: _goBack),
        const SizedBox(height: 20),

        // ── Optimize now ──────────────────────────────────────────────────────
        Text(
          'Optimize for this job',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),

        // Job description field (pre-filled from Step 2 when possible)
        TextField(
          controller: _optimizerJobDescCtrl,
          maxLines: 4,
          minLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Paste or edit the job description...',
            hintStyle:
                TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (_isOptimizing) ...
          [
            LinearProgressIndicator(
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 6),
            Text(
              'Optimizing your resume...',
              style: TextStyle(fontSize: 11, color: cs.primary),
            ),
            const SizedBox(height: 12),
          ]
        else if (_optimizationDone) ...
          [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: cs.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Optimization sent! It will appear in AI Optimized shortly.',
                      style: TextStyle(fontSize: 12, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ]
        else if (_optimizationError != null) ...
          [
            Text(
              _optimizationError!,
              style: TextStyle(fontSize: 11, color: cs.error),
            ),
            const SizedBox(height: 8),
          ]
        else
          const SizedBox(height: 4),

        // Optimize button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed:
                (_isOptimizing || _optimizationDone || _selectedResumeId == null)
                    ? null
                    : _runOptimization,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor:
                  cs.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor:
                  cs.onSurface.withValues(alpha: 0.38),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _optimizationDone ? 'Optimized ✓' : 'Optimize →',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Divider ───────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
                child: Divider(
                    color: cs.outline.withValues(alpha: 0.35), height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or use existing',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            Expanded(
                child: Divider(
                    color: cs.outline.withValues(alpha: 0.35), height: 1)),
          ],
        ),
        const SizedBox(height: 14),

        // ── Select existing AI optimized resume ───────────────────────────────
        Text(
          'Select an AI optimized resume',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),

        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (optimizedResumes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No AI optimized resumes yet. Run optimization above.',
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.45)),
            ),
          )
        else
          ...optimizedResumes.map(
            (r) => _OptimizedResumeItem(
              resume: r,
              isSelected:
                  _optimizedResumeId == r.id && !_optimizationDone,
              onTap: () => setState(() {
                _optimizedResumeId = r.id;
                _optimizationDone = false;
              }),
            ),
          ),

        const SizedBox(height: 24),

        // ── Actions ───────────────────────────────────────────────────────────
        _PrimaryButton(
          label: 'Add to Pipeline',
          onTap: canAdd ? _submitFinal : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _submitWithoutOptimize,
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(
                  color: cs.outline.withValues(alpha: 0.5), width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Add without optimizing',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────────

  static String _companyInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return name.substring(0, math.min(2, name.length)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Progress dots ────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int step;
  const _ProgressDots({required this.step});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final isActive = i < step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Step header ──────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _StepHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Method card ──────────────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: cs.onSurface),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Badge
            if (badge != null) ...[
              const SizedBox(width: 8),
              badge!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── AI badge ─────────────────────────────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'AI auto-fill',
        style: TextStyle(
          fontSize: 10,
          color: cs.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Outline text field ───────────────────────────────────────────────────────

class _OutlineTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;

  const _OutlineTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        floatingLabelStyle: TextStyle(color: cs.primary),
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Field row ────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool aiFilled;

  const _FieldRow({
    required this.label,
    required this.value,
    this.aiFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (aiFilled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI filled',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Keyword chip (missing) ────────────────────────────────────────────────────

class _KeywordChip extends StatelessWidget {
  final String label;
  const _KeywordChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.error.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: cs.onErrorContainer),
      ),
    );
  }
}

// ─── Primary button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ─── Optimized resume item (Step 5) ─────────────────────────────────────────

class _OptimizedResumeItem extends StatelessWidget {
  final Resume resume;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptimizedResumeItem({
    required this.resume,
    required this.isSelected,
    required this.onTap,
  });

  String get _displayName {
    if (resume.targetRole != null && resume.targetRole!.isNotEmpty) {
      if (resume.targetCompany != null && resume.targetCompany!.isNotEmpty) {
        return '${resume.targetRole} @ ${resume.targetCompany}';
      }
      return resume.targetRole!;
    }
    return resume.personal?.currentRole ??
        resume.nickname ??
        'AI Optimized';
  }

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
            color:
                isSelected ? cs.primary : cs.outline.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.auto_awesome, size: 12, color: cs.primary),
                    const SizedBox(width: 4),
                    Text('AI Optimized',
                        style: TextStyle(fontSize: 11, color: cs.primary)),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    'Created $dateStr',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: cs.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── ATS ring painter ─────────────────────────────────────────────────────────

class _AtsRingPainter extends CustomPainter {
  final double score;
  final Color trackColor;
  final Color arcColor;

  const _AtsRingPainter({
    required this.score,
    required this.trackColor,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 5) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Track
    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    // Arc
    paint.color = arcColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (score.clamp(0, 100) / 100),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_AtsRingPainter old) =>
      old.score != score ||
      old.trackColor != trackColor ||
      old.arcColor != arcColor;
}

// ─── Extension helper ─────────────────────────────────────────────────────────

extension _StringLet on String {
  T let<T>(T Function(String) block) => block(this);
}
