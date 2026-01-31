import 'package:flutter/foundation.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';

class ResumeProvider with ChangeNotifier {
  final ResumeService _resumeService = ResumeService();

  List<Resume> _resumes = [];
  bool _isLoading = false;
  Resume? _currentOptimization;

  List<Resume> get resumes => _resumes;
  bool get isLoading => _isLoading;
  Resume? get currentOptimization => _currentOptimization;

  Future<void> loadResumes() async {
    _isLoading = true;
    notifyListeners();

    _resumes = await _resumeService.getResumes();

    _isLoading = false;
    notifyListeners();
  }

  // Add a local resume (UI-only / optimistic) and notify listeners
  void addLocalResume(Resume resume) {
    _resumes.insert(0, resume);
    notifyListeners();
  }

  Future<Resume?> optimizeResume({
    required String resumeText,
    required String jobDescription,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resume = await _resumeService.optimizeResume(
        resumeText: resumeText,
        jobDescription: jobDescription,
      );

      _currentOptimization = resume;
      
      // Reload resumes to include the new one
      await loadResumes();

      _isLoading = false;
      notifyListeners();

      return resume;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearCurrentOptimization() {
    _currentOptimization = null;
    notifyListeners();
  }
}
