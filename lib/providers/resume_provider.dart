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

  Future<Resume?> getResumeById(String resumeId, {String? type}) async {
    try {
      // Primeiro tenta buscar da lista já carregada em memória
      final cachedResume = _resumes.firstWhere(
        (r) => r.id == resumeId,
        orElse: () => Resume(
          id: '',
          type: 'manual',
          createdAt: DateTime.now(),
        ),
      );
      
      // Se encontrou na cache e tem dados completos, retorna
      if (cachedResume.id.isNotEmpty) {
        // Para manual, verifica se tem dados pessoais
        if (cachedResume.type == 'manual' && cachedResume.personal != null) {
          return cachedResume;
        }
        // Para otimizado, usa o objeto da cache (salary_estimate já vem na listagem)
        if (cachedResume.type == 'optimized') {
          return cachedResume;
        }
      }
      
      // Se não encontrou na cache ou não tem dados completos, busca do servidor
      return await _resumeService.getResumeById(resumeId, type: type);
    } catch (e) {
      
      // Se falhou, tenta retornar da cache mesmo assim
      final cachedResume = _resumes.firstWhere(
        (r) => r.id == resumeId,
        orElse: () => Resume(
          id: '',
          type: 'manual',
          createdAt: DateTime.now(),
        ),
      );
      
      return cachedResume.id.isNotEmpty ? cachedResume : null;
    }
  }

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
    required String resumeId,
    required String jobDescription,
    String? targetCompany,
    String? targetRole,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resume = await _resumeService.optimizeResume(
        resumeId: resumeId,
        jobDescription: jobDescription,
        targetCompany: targetCompany,
        targetRole: targetRole,
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

  Future<Resume?> createManualResume(Map<String, dynamic> resumeData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resume = await _resumeService.createManualResume(
        resumeData: resumeData,
      );

      // Reload list to include the new resume
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

  Future<void> deleteResume(String resumeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Encontrar o tipo do currículo antes de deletar
      final resume = _resumes.firstWhere((r) => r.id == resumeId);

      await _resumeService.deleteResume(resumeId, type: resume.type);

      // Remove from local list
      _resumes.removeWhere((resume) => resume.id == resumeId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Resume?> updateManualResume({
    required String resumeId,
    required Map<String, dynamic> resumeData,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resume = await _resumeService.updateManualResume(
        resumeId: resumeId,
        resumeData: resumeData,
      );

      // Reload list to get updated data
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

  Future<Resume?> updateOptimizedResume({
    required String resumeId,
    required Map<String, dynamic> resumeData,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resume = await _resumeService.updateOptimizedResume(
        resumeId: resumeId,
        resumeData: resumeData,
      );

      // Reload list to get updated data
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
