import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../services/resume_service.dart';
import 'pdf_ats_result_screen.dart';

class ResumePdfUploadScreen extends StatefulWidget {
  const ResumePdfUploadScreen({super.key});

  @override
  State<ResumePdfUploadScreen> createState() => _ResumePdfUploadScreenState();
}

class _ResumePdfUploadScreenState extends State<ResumePdfUploadScreen> {
  final ResumeService _resumeService = ResumeService();

  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  bool _isParsing = false;
  String? _errorMessage;

  Future<void> _pickPdf() async {
    setState(() {
      _errorMessage = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() {
        _errorMessage = 'Could not read the file. Please try again.';
      });
      return;
    }

    setState(() {
      _selectedFileName = file.name;
      _selectedFileBytes = file.bytes!.toList();
      _errorMessage = null;
    });
  }

  Future<void> _parsePdf() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });

    try {
      final result = await _resumeService.parsePdfResumeWithScore(
        pdfBytes: _selectedFileBytes!,
        fileName: _selectedFileName!,
      );

      if (!mounted) return;

      // Replace this screen so the user cannot swipe back to re-upload
      await Navigator.of(context).pushReplacement(
        AppTransitions.fadeSlide(
          PdfAtsResultScreen(
            resume: result.resume,
            atsScore: result.atsScore,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '');
      final message = _friendlyError(raw);
      setState(() {
        _isParsing = false;
        _errorMessage = message;
      });
    }
  }

  /// Maps internal/technical error strings to user-friendly messages.
  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('deadline exceeded') ||
        lower.contains('timed out') ||
        lower.contains('timeout')) {
      return 'The AI took too long to respond. Please try again — it usually works on the second attempt.';
    }
    if (lower.contains('openai') || lower.contains('api.openai.com')) {
      return 'The AI service is temporarily unavailable. Please wait a moment and try again.';
    }
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return 'Network error. Check your internet connection and try again.';
    }
    if (lower.contains('not authenticated') || lower.contains('401')) {
      return 'Your session expired. Please log in again.';
    }
    return 'AI parsing failed. Please try again.';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import PDF Resume'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Upload your resume PDF',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our AI will extract your information and pre-fill the resume form for you.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Drop zone / picker area
              GestureDetector(
                onTap: _isParsing ? null : _pickPdf,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: _selectedFileName != null
                        ? AppTheme.primaryColor.withValues(alpha: 0.06)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFileName != null
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: _selectedFileName != null ? 2 : 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedFileName != null
                            ? Icons.picture_as_pdf
                            : Icons.upload_file_outlined,
                        size: 52,
                        color: _selectedFileName != null
                            ? AppTheme.primaryColor
                            : AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedFileName != null) ...[
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _isParsing ? null : _pickPdf,
                          child: const Text('Change file'),
                        ),
                      ] else ...[
                        const Text(
                          'Tap to choose a PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Only PDF files are supported',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline,
                              color: AppTheme.errorColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _parsePdf,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Try again'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(
                                color: AppTheme.errorColor.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              if (_isParsing) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Parsing your resume…',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This may take a few seconds.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _selectedFileName != null ? _parsePdf : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Parse with AI'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
