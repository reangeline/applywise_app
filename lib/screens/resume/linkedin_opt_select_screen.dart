import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/resume_provider.dart';
import '../../config/theme.dart';
import '../../widgets/app_spinner.dart';
import '../../models/resume.dart';
import '../../config/transitions.dart';
import '../../services/resume_service.dart';
import '../subscription/paywall_screen.dart';

class LinkedInOptSelectScreen extends StatefulWidget {
  const LinkedInOptSelectScreen({super.key});

  @override
  State<LinkedInOptSelectScreen> createState() => _LinkedInOptSelectScreenState();
}

class _LinkedInOptSelectScreenState extends State<LinkedInOptSelectScreen> {
  int _selected = 0;
  bool _isOptimizing = false;
  final ResumeService _resumeService = ResumeService();

  Color _scoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getResumeDisplayText(Resume resume) {
    if (resume.type == 'optimized') {
      final role = resume.targetRole ?? resume.personal?.currentRole;
      final company = resume.targetCompany;
      if (role != null && company != null) return '$role — $company';
      if (role != null) return role;
      if (company != null) return company;
      return 'AI Optimized (${resume.createdAt.day}/${resume.createdAt.month}/${resume.createdAt.year})';
    }

    if (resume.nickname?.isNotEmpty == true) return resume.nickname!;

    if (resume.personal != null) {
      final name = resume.personal!.fullName.isNotEmpty
          ? resume.personal!.fullName
          : 'Manual Resume';
      final role = resume.personal!.currentRole;
      return role != null && role.isNotEmpty ? '$name — $role' : name;
    }

    return 'Resume ${resume.id.substring(0, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final resumeProvider = Provider.of<ResumeProvider>(context);
    final resumes = resumeProvider.resumes.where((r) => r.type == 'manual').toList();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Select Resume')),
      body: resumes.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: resumes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final resume = resumes[idx];
                        final isOptimized = resume.type == 'optimized';
                        final company = isOptimized ? resume.targetCompany : null;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: Theme.of(context).cardColor,
                          title: Text(
                            _getResumeDisplayText(resume),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (company != null)
                                Row(
                                  children: [
                                    Icon(Icons.business_outlined,
                                        size: 12, color: AppTheme.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      company,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              Row(
                                children: [
                                  Icon(
                                    isOptimized
                                        ? Icons.auto_awesome
                                        : Icons.edit_note,
                                    size: 12,
                                    color: isOptimized
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOptimized ? 'AI Optimized' : 'Manual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOptimized
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (resume.score != null) ...[
                                    const Text('  ·  ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textTertiary)),
                                    Text(
                                      '${resume.score!.toStringAsFixed(0)}% match',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _scoreColor(resume.score!),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          leading: Radio<int>(
                            value: idx,
                            groupValue: _selected,
                            onChanged: (v) => setState(() => _selected = v ?? 0),
                          ),
                          onTap: () => setState(() => _selected = idx),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (resumes.isEmpty || _isOptimizing) ? null : () async {
                        final isPro = subscriptionProvider.isPro;
                        if (!isPro) {
                          _showPremiumRequiredDialog(context);
                          return;
                        }
                        await _handleLinkedInOptimize(resumes[_selected]);
                      },
                      child: _isOptimizing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: AppSpinnerSmall(),
                            )
                          : const Text('Optimize for LinkedIn'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Future<void> _handleLinkedInOptimize(Resume resume) async {
    setState(() => _isOptimizing = true);

    try {
      // Start the job — fire and forget (backend sends FCM when done)
      await _resumeService.startLinkedInOptimize(resumeId: resume.id);

      if (!mounted) return;

      // Show guidance sheet; it will pop this screen on dismissal
      _showLinkedInQueuedSheet(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start LinkedIn optimization: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  void _showLinkedInQueuedSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0077B5), Color(0xFF00A0DC)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.badge, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'LinkedIn Optimization Started!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'AI is crafting your headline, about section, experiences and skills. You\'ll receive a push notification when it\'s ready.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            // Where to find it
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0077B5).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0077B5).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Color(0xFF0077B5)),
                      SizedBox(width: 6),
                      Text(
                        'Where to find your result',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0077B5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _stepRow(
                    icon: Icons.description_outlined,
                    label: 'Tap  Resumes  in the bottom bar',
                  ),
                  const SizedBox(height: 8),
                  _stepRow(
                    icon: Icons.auto_awesome,
                    label: 'Select the  AI Optimized  tab',
                  ),
                  const SizedBox(height: 8),
                  _stepRow(
                    icon: Icons.badge,
                    label: 'Tap the LinkedIn Optimization card',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // close sheet
                  Navigator.of(ctx).pop(); // close select screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got it', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0077B5).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF0077B5)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Resumes Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a resume first to optimize it for LinkedIn',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPremiumRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Premium Feature',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'LinkedIn Optimization is only available for Premium users. Upgrade now to unlock this feature!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                      Navigator.of(context).pop();
                    Navigator.of(context).push(
                      AppTransitions.slideUp(const PaywallScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Upgrade to Premium'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Maybe Later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkedInPollingDialog extends StatefulWidget {
  const _LinkedInPollingDialog();

  @override
  State<_LinkedInPollingDialog> createState() => _LinkedInPollingDialogState();
}

class _LinkedInPollingDialogState extends State<_LinkedInPollingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _dots = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _animController.reset();
          _animController.forward();
          if (mounted) setState(() => _dots = (_dots + 1) % 4);
        }
      });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotsText = '.' * _dots;
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Optimizing for LinkedIn$dotsText',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'AI is crafting your headline, about section, experience bullets, and skills. This may take up to 2 minutes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
