import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../widgets/app_spinner.dart';
import '../../models/resume.dart';
import '../../providers/resume_provider.dart';
import '../../services/analytics_service.dart';
import 'resume_add_screen.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/pro_feature_gate.dart';

class ResumeOptimizerScreen extends StatefulWidget {
  final String? initialJobDescription;

  const ResumeOptimizerScreen({super.key, this.initialJobDescription});

  @override
  State<ResumeOptimizerScreen> createState() => _ResumeOptimizerScreenState();
}

class _ResumeOptimizerScreenState extends State<ResumeOptimizerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resumeController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  bool _isLoading = false;
  String? _selectedResumeId;
  final _companyController = TextEditingController();
  final _targetRoleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill job description if opened from Share Extension
    if (widget.initialJobDescription != null && widget.initialJobDescription!.isNotEmpty) {
      _jobDescriptionController.text = widget.initialJobDescription!;
    }
    // load saved resumes after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resumeProvider =
          Provider.of<ResumeProvider>(context, listen: false);
      resumeProvider.loadResumes();
    });
  }

  @override
  void didUpdateWidget(ResumeOptimizerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if parent passes new shared text after app resumes
    if (widget.initialJobDescription != null &&
        widget.initialJobDescription!.isNotEmpty &&
        widget.initialJobDescription != oldWidget.initialJobDescription) {
      _jobDescriptionController.text = widget.initialJobDescription!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final resumeProvider = Provider.of<ResumeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimize Resume'),
        automaticallyImplyLeading: false,
      ),
      body: ProFeatureGate(
        isPro: subscriptionProvider.isPro,
        credits: subscriptionProvider.credits,
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
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
                    _buildJobTargetFields(),
                    const SizedBox(height: 24),
                    _buildJobDescriptionInput(),
                    const SizedBox(height: 32),
                    _buildOptimizeButton(resumeProvider),
                  ],
                ),
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
              await Navigator.of(context).push(
                  AppTransitions.slideRight(const ResumeAddScreen()));
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
            ? const Center(child: AppSpinner())
            : _buildResumesList(resumeProvider)
      ],
    );
  }

  Widget _buildResumesList(ResumeProvider resumeProvider) {
    // Filtrar apenas currículos manuais
    final manualResumes =
        resumeProvider.resumes.where((r) => r.type == 'manual').toList();

    if (manualResumes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No manual resumes yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a manual resume to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedResumeId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Select Resume',
          ),
          hint: const Text('Choose a manual resume'),
          items: manualResumes.map((resume) {
            final fullName = resume.personal?.fullName ?? '';
            final name = fullName.isNotEmpty ? fullName : (resume.nickname ?? 'Resume');
            final role = resume.personal?.currentRole;
            final date = resume.createdAt.toLocal().toString().split(' ').first;

            return DropdownMenuItem<String>(
              value: resume.id,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (role != null && role.isNotEmpty)
                      TextSpan(
                        text: '  ·  $role',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    TextSpan(
                      text: '  $date',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedResumeId = value),
        ),
        const SizedBox(height: 12),
        if (_selectedResumeId != null) _buildResumePreview(manualResumes),
      ],
    );
  }

  Widget _buildResumePreview(List<Resume> manualResumes) {
    final selected = manualResumes.firstWhere(
      (r) => r.id == _selectedResumeId,
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome e cargo
            if (selected.personal?.fullName != null) ...[
              Text(
                selected.personal!.fullName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (selected.personal?.currentRole != null) ...[
                const SizedBox(height: 4),
                Text(
                  selected.personal!.currentRole!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Informações de contato
            if (selected.personal != null) ...[
              if (selected.personal!.email.isNotEmpty)
                _buildInfoRow(Icons.email, selected.personal!.email),
              if (selected.personal!.phone != null &&
                  selected.personal!.phone!.isNotEmpty)
                _buildInfoRow(Icons.phone, selected.personal!.phone!),
              if (selected.personal!.city != null &&
                  selected.personal!.city!.isNotEmpty)
                _buildInfoRow(Icons.location_on,
                    '${selected.personal!.city}${selected.personal!.state != null ? ', ${selected.personal!.state}' : ''}'),
            ],

            // Experiências
            if (selected.experiences != null &&
                selected.experiences!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.work, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Experience',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...selected.experiences!.take(2).map((exp) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.role,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          exp.company,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  )),
              if (selected.experiences!.length > 2)
                Text(
                  '+${selected.experiences!.length - 2} more experiences',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
            ],

            // Educação
            if (selected.education != null &&
                selected.education!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.school, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Education',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...selected.education!.take(1).map((edu) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edu.degree,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        edu.institution,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  )),
            ],

            const SizedBox(height: 12),
            Text(
              'Created: ${selected.createdAt.toLocal().toString().split(' ').first}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTargetFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Target',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  hintText: 'e.g. Google',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _targetRoleController,
                decoration: const InputDecoration(
                  labelText: 'Target Position',
                  hintText: 'e.g. Backend Engineer',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
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
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          autofocus: false,
          enableInteractiveSelection: true,
          decoration: const InputDecoration(
            hintText: 'Paste the job description here...',
            border: OutlineInputBorder(),
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
                child: AppSpinnerSmall(),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isLoading ? 'Optimizing...' : 'Optimize Resume'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Future<void> _handleOptimize(ResumeProvider resumeProvider) async {
    if (!_formKey.currentState!.validate()) return;

    // require a selected resume
    if (_selectedResumeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a resume to optimize')));
      return;
    }

    setState(() => _isLoading = true);

    final company = _companyController.text.trim().isEmpty ? null : _companyController.text.trim();
    final role = _targetRoleController.text.trim().isEmpty ? null : _targetRoleController.text.trim();

    AnalyticsService.instance.logResumeOptimizeStarted(
      targetCompany: company,
      targetRole: role,
    );

    try {
      final selected =
          resumeProvider.resumes.firstWhere((r) => r.id == _selectedResumeId);

      await resumeProvider.optimizeResume(
        resumeId: selected.id,
        jobDescription: _jobDescriptionController.text,
        targetCompany: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        targetRole: _targetRoleController.text.trim().isEmpty ? null : _targetRoleController.text.trim(),
      );

      if (!mounted) return;

      // Limpar loading antes de navegar
      setState(() => _isLoading = false);

      AnalyticsService.instance.logResumeOptimizeSuccess(
        targetCompany: company,
        targetRole: role,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Resume sent for optimization! It is being processed and will appear in your Optimized Resumes list shortly.',
          ),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 5),
        ),
      );
      
      // Resetar o formulário após envio bem-sucedido
      _jobDescriptionController.clear();
      _companyController.clear();
      _targetRoleController.clear();
      setState(() => _selectedResumeId = null);
      
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      AnalyticsService.instance.logResumeOptimizeError(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to optimize: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _resumeController.dispose();
    _jobDescriptionController.dispose();
    _companyController.dispose();
    _targetRoleController.dispose();
    super.dispose();
  }
}
