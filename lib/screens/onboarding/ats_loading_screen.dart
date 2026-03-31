import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/onboarding_ats_service.dart';
import 'score_partial_screen.dart';

class AtsLoadingScreen extends StatefulWidget {
  const AtsLoadingScreen({super.key});

  @override
  State<AtsLoadingScreen> createState() => _AtsLoadingScreenState();
}

class _AtsLoadingScreenState extends State<AtsLoadingScreen> {
  final OnboardingAtsService _service = OnboardingAtsService();

  bool _hasError = false;
  String? _errorMessage;

  // Status messages cycled during loading
  static const List<String> _messages = [
    'Processing your resume...',
    'Analyzing keywords...',
    'Checking ATS formatting...',
    'Identifying critical issues...',
    'Calculating score...',
  ];
  int _msgIndex = 0;

  // Check-list step labels (aligned with _messages)
  static const List<String> _checkLabels = [
    'Document structure',
    'Relevant keywords',
    'ATS-compatible formatting',
    'Critical sections',
  ];

  @override
  void initState() {
    super.initState();
    _startCycling();
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
  }

  void _startCycling() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _hasError) return;
      setState(() {
        _msgIndex = (_msgIndex + 1) % _messages.length;
      });
      _startCycling();
    });
  }

  Future<void> _analyze() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final provider = context.read<OnboardingProvider>();

      final result = switch (provider.entryMode) {
        'pdf' when provider.pdfBytes != null && provider.pdfFileName != null =>
          await _service.analyzeWithPdf(
            pdfBytes: provider.pdfBytes!,
            fileName: provider.pdfFileName!,
          ),
        'manual' when provider.resumeText != null =>
          await _service.analyzeWithText(resumeText: provider.resumeText!),
        _ => throw Exception('No resume data found.'),
      };

      if (!mounted) return;
      provider.setAtsResult(result);

      // For PDF uploads, persist the structured parsed_data so it can be
      // included in the signup request (email) or sent to resumes/manual (social).
      if (provider.entryMode == 'pdf') {
        final parsedData = result.rawData['parsed_data'] as Map<String, dynamic>?;
        if (parsedData != null) {
          provider.setParsedResumeData(parsedData);
        }
      }

      Navigator.of(context).pushReplacement(
        AppTransitions.fadeSlide(const ScorePartialScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('host')) {
      return 'No internet connection.\nCheck your network and try again.';
    }
    if (msg.contains('timeout')) {
      return 'Analysis is taking longer than expected.\nPlease try again.';
    }
    return 'An error occurred while analyzing your resume.\nPlease try again.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _hasError,
      child: Scaffold(
        body: SafeArea(
          child: _hasError ? _buildError() : _buildLoading(),
        ),
      ),
    );
  }

  // ─── Loading state ───────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitDoubleBounce(
              color: AppTheme.primaryColor,
              size: 72,
            ),
            const SizedBox(height: 40),
            Text(
              'Analyzing your resume',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _messages[_msgIndex],
                key: ValueKey(_msgIndex),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            _buildCheckList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckList() {
    return Column(
      children: List.generate(_checkLabels.length, (i) {
        final isDone = i < _msgIndex;
        final isCurrent = i == _msgIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isDone
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 22,
                          key: ValueKey('done'),
                        )
                      : isCurrent
                          ? CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.primaryColor,
                              key: const ValueKey('spinner'),
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: AppTheme.borderColor,
                              size: 22,
                              key: const ValueKey('todo'),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _checkLabels[i],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDone || isCurrent
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── Error state ─────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analysis Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _analyze,
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
