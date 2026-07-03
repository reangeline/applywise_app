import 'package:flutter/foundation.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';

class ResumeProvider with ChangeNotifier {
  final ResumeService _resumeService = ResumeService();

  List<Resume> _resumes = [];
  bool _isLoading = false;
  Resume? _currentOptimization;
  DateTime? _lastFetched;

  static const _cacheTtl = Duration(minutes: 5);

  List<Resume> get resumes => _resumes;
  bool get isLoading => _isLoading;
  Resume? get currentOptimization => _currentOptimization;

  bool get _isCacheFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _cacheTtl;

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

  Future<void> loadResumes({bool force = false}) async {
    // If cache is fresh and not forced, return immediately — instant display
    if (!force && _isCacheFresh) return;

    // If we already have data (stale), refresh silently in background
    if (_resumes.isNotEmpty && !force) {
      _resumeService.getResumes().then((fresh) {
        _resumes = fresh;
        _lastFetched = DateTime.now();
        notifyListeners();
      }).catchError((_) {});
      return;
    }

    // First load or forced refresh — show loading indicator
    _isLoading = true;
    notifyListeners();

    try {
      _resumes = await _resumeService.getResumes();
      _lastFetched = DateTime.now();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      // Insert the new optimized resume at the front without a full reload
      if (resume != null) {
        _resumes.insert(0, resume);
        _lastFetched = DateTime.now();
      }

      _isLoading = false;
      notifyListeners();

      return resume;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Polls the backend until the optimized resume has a [score] (i.e. the
  /// async processing finished). Delegates to [ResumeService.pollOptimizedResume].
  Future<Resume> pollOptimizedResume(String resumeId) =>
      _resumeService.pollOptimizedResume(resumeId);

  Future<Resume?> createManualResume(Map<String, dynamic> resumeData) async {
    try {
      final resume = await _resumeService.createManualResume(
        resumeData: resumeData,
      );

      _resumes.insert(0, resume);
      _lastFetched = DateTime.now();
      notifyListeners();

      return resume;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteResume(String resumeId) async {
    // Optimistic removal
    final idx = _resumes.indexWhere((r) => r.id == resumeId);
    Resume? removed;
    if (idx >= 0) {
      removed = _resumes.removeAt(idx);
      notifyListeners();
    }

    try {
      if (removed != null) {
        await _resumeService.deleteResume(resumeId, type: removed.type);
      }
    } catch (e) {
      // Roll back on failure
      if (removed != null && idx >= 0) {
        _resumes.insert(idx, removed);
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<Resume?> updateManualResume({
    required String resumeId,
    required Map<String, dynamic> resumeData,
  }) async {
    try {
      final resume = await _resumeService.updateManualResume(
        resumeId: resumeId,
        resumeData: resumeData,
      );

      _replaceInList(resume);

      return resume;
    } catch (e) {
      rethrow;
    }
  }

  Future<Resume?> updateOptimizedResume({
    required String resumeId,
    required Map<String, dynamic> resumeData,
  }) async {
    try {
      final resume = await _resumeService.updateOptimizedResume(
        resumeId: resumeId,
        resumeData: resumeData,
      );

      _replaceInList(resume);

      return resume;
    } catch (e) {
      rethrow;
    }
  }

  /// Replaces the matching item in [_resumes] in-place and notifies listeners.
  void _replaceInList(Resume updated) {
    final i = _resumes.indexWhere((r) => r.id == updated.id);
    if (i >= 0) {
      _resumes[i] = updated;
    } else {
      _resumes.insert(0, updated);
    }
    notifyListeners();
  }

  void clearCurrentOptimization() {
    _currentOptimization = null;
    notifyListeners();
  }

  void reset() {
    _resumes = [];
    _isLoading = false;
    _currentOptimization = null;
    _lastFetched = null;
    notifyListeners();
  }
}
