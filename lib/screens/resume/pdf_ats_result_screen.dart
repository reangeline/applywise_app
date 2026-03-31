import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../models/resume.dart';
import 'resume_manual_form.dart';

/// Displayed after parsing a PDF in the authenticated (manual) flow.
/// Shows the ATS score extracted from the parse-pdf response and lets
/// the user proceed to review/edit their parsed resume data.
class PdfAtsResultScreen extends StatefulWidget {
  final Resume resume;
  final int atsScore;

  const PdfAtsResultScreen({
    super.key,
    required this.resume,
    required this.atsScore,
  });

  @override
  State<PdfAtsResultScreen> createState() => _PdfAtsResultScreenState();
}

class _PdfAtsResultScreenState extends State<PdfAtsResultScreen> {
  @override
  Widget build(BuildContext context) {
    final resume = widget.resume;
    final atsScore = widget.atsScore;
    final Color scoreColor = atsScore < 50
        ? AppTheme.errorColor
        : atsScore < 75
            ? const Color(0xFFF59E0B)
            : AppTheme.successColor;

    final String scoreLabel = atsScore < 50
        ? 'Resume too weak for ATS'
        : atsScore < 75
            ? 'Resume needs improvements'
            : 'Resume in good shape';

    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Resume Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
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
              const SizedBox(height: 28),
              // Score card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: scoreColor.withValues(alpha: 0.3), width: 2),
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
                    _ScoreCircle(score: atsScore, color: scoreColor),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        scoreLabel,
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
              ),
              // Improvement points
              if (resume.atsImprovements?.isNotEmpty == true) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 20, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'Improvement Points',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...resume.atsImprovements!.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final point = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            point,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              // Info banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_outlined,
                        color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Review and edit your parsed resume data before saving.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      AppTransitions.slideRight(
                        ResumeManualForm(
                          initialResume: resume,
                          // Always create — parse-pdf never persists to the DB
                          forceCreate: true,
                        ),
                      ),
                    );
                    // If the form was saved, pop back to the resume list
                    if (saved == true && mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Review & Edit Resume',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

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
