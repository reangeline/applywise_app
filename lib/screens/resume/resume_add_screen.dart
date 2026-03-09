import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import 'package:provider/provider.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/app_spinner.dart';
import 'resume_manual_form.dart';

class ResumeAddScreen extends StatefulWidget {
  const ResumeAddScreen({super.key});

  @override
  State<ResumeAddScreen> createState() => _ResumeAddScreenState();
}

class _ResumeAddScreenState extends State<ResumeAddScreen> {
  Widget _buildManualEntryCTA() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(AppTransitions.slideRight(const ResumeManualForm()));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note, color: AppTheme.secondaryColor),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fill manually', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Add your information step by step (quick and intuitive).'),
                  ],
                ),
              ),
              ElevatedButton(onPressed: () { Navigator.of(context).push(AppTransitions.slideRight(const ResumeManualForm())); }, child: const Text('Start')),
            ],
          ),
        ),
      ),
    );
  }
  // Note: detailed manual form moved to ResumeManualForm screen.

  @override
  Widget build(BuildContext context) {
    final resumeProvider = Provider.of<ResumeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Resume')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Add your resume', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Fill in your details to get started.'),
              const SizedBox(height: 16),
              _buildManualEntryCTA(),
              const SizedBox(height: 18),

              // Existing resumes (uploaded or manual)
              Expanded(
                child: resumeProvider.isLoading
                    ? const Center(child: AppSpinner())
                    : resumeProvider.resumes.isEmpty
                        ? Center(child: Text('No resumes yet', style: Theme.of(context).textTheme.bodyMedium))
                        : ListView.builder(
                            itemCount: resumeProvider.resumes.length,
                            itemBuilder: (context, i) {
                              final r = resumeProvider.resumes[i];
                              return ListTile(
                                leading: const Icon(Icons.description),
                                title: Text('Resume ${r.id.substring(0, 6)}'),
                                subtitle: Text('${(r.score ?? 0).toStringAsFixed(0)}% • ${r.createdAt.toLocal().toString().split(' ').first}'),
                                onTap: () => Navigator.of(context).pop(),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
