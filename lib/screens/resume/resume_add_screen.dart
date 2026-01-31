import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/resume_provider.dart';
import 'resume_manual_form.dart';

class ResumeAddScreen extends StatefulWidget {
  const ResumeAddScreen({super.key});

  @override
  State<ResumeAddScreen> createState() => _ResumeAddScreenState();
}

class _ResumeAddScreenState extends State<ResumeAddScreen> {

  Widget _buildUploadCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: integration - open file picker
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.upload_file, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Upload PDF or DOC', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Let our AI extract your information automatically.'),
                  ],
                ),
              ),
              ElevatedButton(onPressed: () {}, child: const Text('Upload')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryCTA() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResumeManualForm()));
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Fill manually', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Add your information step by step (quick and intuitive).'),
                  ],
                ),
              ),
              ElevatedButton(onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResumeManualForm())); }, child: const Text('Start')),
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Add your resume', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Choose to upload a file or fill in manually.'),
              const SizedBox(height: 16),
              _buildUploadCard(),
              const SizedBox(height: 12),
              _buildManualEntryCTA(),
              const SizedBox(height: 18),

              // Existing resumes (uploaded or manual)
              Expanded(
                child: resumeProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : resumeProvider.resumes.isEmpty
                        ? Center(child: Text('No resumes yet', style: Theme.of(context).textTheme.bodyMedium))
                        : ListView.builder(
                            itemCount: resumeProvider.resumes.length,
                            itemBuilder: (context, i) {
                              final r = resumeProvider.resumes[i];
                              return ListTile(
                                leading: const Icon(Icons.description),
                                title: Text('Resume ${r.id.substring(0, 6)}'),
                                subtitle: Text('${r.score.toStringAsFixed(0)}% • ${r.createdAt.toLocal().toString().split(' ').first}'),
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
