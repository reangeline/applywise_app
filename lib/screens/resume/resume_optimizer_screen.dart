import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/resume_provider.dart';
import 'resume_add_screen.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/pro_feature_gate.dart';

class ResumeOptimizerScreen extends StatefulWidget {
  const ResumeOptimizerScreen({super.key});

  @override
  State<ResumeOptimizerScreen> createState() => _ResumeOptimizerScreenState();
}

class _ResumeOptimizerScreenState extends State<ResumeOptimizerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resumeController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  bool _isLoading = false;
  String? _selectedResumeId;

  @override
  void initState() {
    super.initState();
    // load saved resumes after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resumeProvider = Provider.of<ResumeProvider>(context, listen: false);
      resumeProvider.loadResumes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final resumeProvider = Provider.of<ResumeProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Optimize Resume'),
        automaticallyImplyLeading: false,
      ),
      body: ProFeatureGate(
        isPro: subscriptionProvider.isPro,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildResumeInput(resumeProvider),
                  const SizedBox(height: 24),
                  _buildJobDescriptionInput(),
                  const SizedBox(height: 32),
                  _buildOptimizeButton(resumeProvider),
                  if (resumeProvider.currentOptimization != null) ...[
                    const SizedBox(height: 32),
                    _buildResults(resumeProvider),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI will optimize your resume to match the job description',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeInput(ResumeProvider resumeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Resume',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResumeAddScreen()));
              // reload resumes after returning
              await resumeProvider.loadResumes();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        resumeProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : resumeProvider.resumes.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // When no real resumes, show only mock dropdown (no 'No saved resumes yet' placeholder)
                      Builder(builder: (context) {
                        final mockResumes = [
                          {
                            'id': 'mock-1',
                            'nickname': 'Sample Resume — Product Manager',
                            'created': DateTime.now().toLocal().toString().split(' ').first,
                            'text': 'Product Manager\nExperienced PM with 6 years leading cross-functional teams, product strategy, and go-to-market execution.\nLed roadmap initiatives that increased user engagement by 30%.'
                          },
                          {
                            'id': 'mock-2',
                            'nickname': 'Sample Resume — Senior Engineer',
                            'created': DateTime.now().subtract(Duration(days: 30)).toLocal().toString().split(' ').first,
                            'text': 'Senior Engineer\nBackend specialist with 8 years building scalable APIs and microservices.\nOptimized systems to improve throughput and reliability, reducing latency by 40%.'
                          }
                        ];

                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedResumeId,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          hint: const Text('Select a sample resume'),
                          items: mockResumes.map((r) {
                            return DropdownMenuItem(
                              value: (r['id'] ?? '').toString(),
                              child: Text('${(r['nickname'] ?? '').toString()} • ${(r['created'] ?? '').toString()}'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedResumeId = v),
                        );
                      }),

                      const SizedBox(height: 12),
                      if (_selectedResumeId != null && _selectedResumeId!.startsWith('mock-')) ...[
                        Builder(builder: (context) {
                          final mock = _selectedResumeId == 'mock-1'
                              ? {
                                  'nickname': 'Sample Resume — Product Manager',
                                  'created': DateTime.now().toLocal().toString().split(' ').first,
                                  'text': 'Product Manager\nExperienced PM with 6 years leading cross-functional teams, product strategy, and go-to-market execution.\nLed roadmap initiatives that increased user engagement by 30%.'
                                }
                              : {
                                  'nickname': 'Sample Resume — Senior Engineer',
                                  'created': DateTime.now().subtract(Duration(days: 30)).toLocal().toString().split(' ').first,
                                  'text': 'Senior Engineer\nBackend specialist with 8 years building scalable APIs and microservices.\nOptimized systems to improve throughput and reliability, reducing latency by 40%.'
                                };
                          final textLines = (mock['text'] ?? '').toString().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
                          final previewLines = textLines.take(3).toList();
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mock['nickname']!, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  ...previewLines.map((line) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('• ', style: TextStyle(fontSize: 14)),
                                            Expanded(child: Text(line, style: Theme.of(context).textTheme.bodyMedium)),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 6),
                                  Text('Created: ${mock['created']!}', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      // Build dropdown items from real resumes
                      if (resumeProvider.resumes.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedResumeId,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          hint: const Text('Select a resume'),
                          items: resumeProvider.resumes.map((r) {
                            return DropdownMenuItem(
                              value: r.id,
                              child: Text('${r.optimizedText.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'Resume ${r.id.substring(0,6)}')} • ${r.createdAt.toLocal().toString().split(' ').first}'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedResumeId = v),
                        ),
                      ] else ...[
                        // Show mock dropdown when no real resumes
                        Builder(builder: (context) {
                          final mockResumes = [
                            {
                              'id': 'mock-1',
                              'nickname': 'Sample Resume — Product Manager',
                              'created': DateTime.now().toLocal().toString().split(' ').first,
                              'text': 'Product Manager\nExperienced PM with 6 years...'
                            },
                            {
                              'id': 'mock-2',
                              'nickname': 'Sample Resume — Senior Engineer',
                              'created': DateTime.now().subtract(Duration(days: 30)).toLocal().toString().split(' ').first,
                              'text': 'Senior Engineer\nBackend specialist with 8 years...'
                            }
                          ];

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedResumeId,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            hint: const Text('Select a sample resume'),
                            items: mockResumes.map((r) {
                              return DropdownMenuItem(
                                  value: (r['id'] ?? '').toString(),
                                  child: Text('${(r['nickname'] ?? '').toString()} • ${(r['created'] ?? '').toString()}'),
                                );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedResumeId = v),
                          );
                        }),
                      ],

                      const SizedBox(height: 12),
                      if (_selectedResumeId != null) ...[
                        Builder(builder: (context) {
                          if (_selectedResumeId!.startsWith('mock-')) {
                            final mock = _selectedResumeId == 'mock-1'
                                ? {
                                    'nickname': 'Sample Resume — Product Manager',
                                    'created': DateTime.now().toLocal().toString().split(' ').first,
                                    'text': 'Product Manager\nExperienced PM with 6 years leading cross-functional teams, product strategy, and go-to-market execution.\nLed roadmap initiatives that increased user engagement by 30%.'
                                  }
                                : {
                                    'nickname': 'Sample Resume — Senior Engineer',
                                    'created': DateTime.now().subtract(Duration(days: 30)).toLocal().toString().split(' ').first,
                                    'text': 'Senior Engineer\nBackend specialist with 8 years building scalable APIs and microservices.\nOptimized systems to improve throughput and reliability, reducing latency by 40%.'
                                  };
                            final textLines = (mock['text'] ?? '').toString().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
                            final previewLines = textLines.take(3).toList();
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mock['nickname']!, style: Theme.of(context).textTheme.titleMedium),

                                    const SizedBox(height: 8),
                                    ...previewLines.map((line) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('• ', style: TextStyle(fontSize: 14)),
                                              Expanded(child: Text(line, style: Theme.of(context).textTheme.bodyMedium)),
                                            ],
                                          ),
                                        )),
                                    const SizedBox(height: 6),
                                    Text('Created: ${mock['created']!}', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            final selected = resumeProvider.resumes.firstWhere((r) => r.id == _selectedResumeId, orElse: () => resumeProvider.resumes.first);
                            final nickname = selected.optimizedText.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'Resume ${selected.id.substring(0, 6)}');
                            final created = selected.createdAt.toLocal().toString().split(' ').first;
                            final textLines = selected.optimizedText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
                            final previewLines = textLines.take(3).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(nickname, style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 6),
                                        Text('Created: $created', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...previewLines.map((line) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(fontSize: 14)),
                                          Expanded(child: Text(line, style: Theme.of(context).textTheme.bodyMedium)),
                                        ],
                                      ),
                                    )),
                              ],
                            );
                          }
                        }),
                      ],
                    ],
                  )
      ],
    );
  }

  Widget _buildJobDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Description',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _jobDescriptionController,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste the job description here...',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the job description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOptimizeButton(ResumeProvider resumeProvider) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _handleOptimize(resumeProvider),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isLoading ? 'Optimizing...' : 'Optimize Resume'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildResults(ResumeProvider resumeProvider) {
    final optimization = resumeProvider.currentOptimization!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Match Score',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${optimization.score.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Optimized Resume',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            optimization.optimizedText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Suggestions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...optimization.suggestions.map((suggestion) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _handleOptimize(ResumeProvider resumeProvider) async {
    if (!_formKey.currentState!.validate()) return;

    // require a selected resume
    if (_selectedResumeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a resume to optimize')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selected = resumeProvider.resumes.firstWhere((r) => r.id == _selectedResumeId);
      await resumeProvider.optimizeResume(
        resumeText: selected.optimizedText,
        jobDescription: _jobDescriptionController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume optimized successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to optimize: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _resumeController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }
}
