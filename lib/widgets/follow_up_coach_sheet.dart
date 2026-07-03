import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/job_application.dart';
import '../providers/pipeline_provider.dart';
import '../services/pipeline_service.dart';class FollowUpCoachSheet extends StatefulWidget {
  final JobApplication job;
  final void Function(JobApplication updated) onJobUpdated;

  const FollowUpCoachSheet({
    super.key,
    required this.job,
    required this.onJobUpdated,
  });

  @override
  State<FollowUpCoachSheet> createState() => _FollowUpCoachSheetState();
}

class _FollowUpCoachSheetState extends State<FollowUpCoachSheet> {
  String _tone = 'default';
  String _generatedMessage = '';
  bool _isGenerating = false;
  bool _isSending = false;
  String? _error;
  // Resolved job (may be synced version with real id)
  late JobApplication _job;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _generateMessage();
  }

  Future<void> _generateMessage() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      // Sync job to backend first if it was added offline (id is empty)
      if (_job.id.isEmpty && mounted) {
        final pipeline = Provider.of<PipelineProvider>(context, listen: false);
        _job = await pipeline.syncJobIfNeeded(_job);
      }

      final content = await PipelineService().generateCoachContent(
        jobId: _job.id,
        stage: _job.stage,
        jobTitle: _job.jobTitle,
        companyName: _job.companyName,
        location: _job.location,
        atsScore: _job.atsScore,
        resumeVersion: _job.resumeVersion,
        jobDescription: _job.jobDescription,
        jobUrl: _job.jobUrl,
        matchedKeywords: _job.matchedKeywords,
        missingKeywords: _job.missingKeywords,
        daysSinceApplied: _daysSinceApplied,
        tone: _tone,
      );
      if (mounted) {
        setState(() {
          _generatedMessage = content;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isGenerating = false;
        });
      }
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

  Future<void> _copyAndLog() async {
    await Clipboard.setData(ClipboardData(text: _generatedMessage));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));

    setState(() => _isSending = true);
    try {
      final updated = await PipelineService()
          .logFollowUp(_job.id, 'email', _generatedMessage);
      if (!mounted) return;

      // If backend didn't return timeline events, add one client-side
      final hasEvent = updated.timeline.any((e) => e.type == 'follow_up_sent');
      final finalJob = hasEvent
          ? updated
          : updated.copyWith(
              timeline: [
                ..._job.timeline,
                TimelineEvent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: 'follow_up_sent',
                  label: 'Follow-up sent',
                  detail: '',
                  createdAt: DateTime.now(),
                ),
              ],
            );

      widget.onJobUpdated(finalJob);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 16, color: cs.primary),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Follow-up coach',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            // Context line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_job.companyName} · ${_job.jobTitle} · $_daysSinceApplied days since applied',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 12),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Generated message box
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GENERATED MESSAGE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isGenerating)
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(
                                  color: cs.primary, strokeWidth: 2),
                            ),
                          )
                        else if (_error != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Could not generate message.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _generateMessage,
                                child: const Text('Try again'),
                              ),
                            ],
                          )
                        else
                          Text(
                            _generatedMessage,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tone buttons
                  Row(
                    children: [
                      _toneButton('More formal', 'formal'),
                      const SizedBox(width: 6),
                      _toneButton('Shorter', 'shorter'),
                      const SizedBox(width: 6),
                      _toneButton('Regenerate', 'regenerate'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Fixed bottom button — always visible, not inside scroll area
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              child: ElevatedButton(
                  onPressed:
                      (_isGenerating || _isSending) ? null : _copyAndLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    minimumSize: const Size(double.infinity, 52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSending
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: cs.onPrimary, strokeWidth: 2),
                        )
                      : const Text(
                          'Copy & log as sent',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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

  Widget _toneButton(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: _isGenerating
              ? null
              : () {
                  if (value == 'regenerate') {
                    _generateMessage();
                  } else {
                    setState(() => _tone = value);
                    _generateMessage();
                  }
                },
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: cs.outline.withOpacity(0.5)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child:
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface)),
        ),
      ),
    );
  }

}
