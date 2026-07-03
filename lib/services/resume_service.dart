import '../config/constants.dart';
import '../models/resume.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class ResumeService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();

  Future<Resume?> optimizeResume({
    required String resumeId,
    required String jobDescription,
    String? targetCompany,
    String? targetRole,
  }) async {
    try {
      final pushReady = await _notificationService
          .ensurePushRegistrationForCurrentSession();
      if (!pushReady) {
        throw Exception(
          'Push notifications are not ready for this session yet. Please try again in a moment.',
        );
      }

      final token = await _storageService.getAccessToken();
      if (token == null) return null;

      final body = <String, dynamic>{
        'resume_id': resumeId,
        'job_description': jobDescription,
      };
      if (targetCompany != null) body['target_company'] = targetCompany;
      if (targetRole != null) body['target_role'] = targetRole;

      final response = await _apiService.post(
        AppConstants.optimizeResumeEndpoint,
        body,
        token: token,
      );

      return Resume.fromJson(response);
    } catch (e) {
      throw Exception('Failed to optimize resume: $e');
    }
  }

  /// Polls until the backend optimization is complete or [maxAttempts] is reached.
  ///
  /// Strategy:
  ///  1. Try [GET /api/v1/resumes/optimized/{id}] directly.
  ///  2. If that returns a still-pending response, fall back to scanning the
  ///     list endpoint [GET /api/v1/resumes/optimized] for the matching ID.
  ///  3. Completion is detected by presence of a score, non-empty suggestions,
  ///     non-empty optimized_text, OR a non-pending status value.
  Future<Resume> pollOptimizedResume(
    String jobOrResumeId, {
    int maxAttempts = 24,
    Duration interval = const Duration(seconds: 5),
  }) async {
    final token = await _storageService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);

      // ── 1. Job status endpoint — the ID returned by POST /optimize is a job ID ──
      try {
        final jobResp = await _apiService.get(
          '${AppConstants.optimizeJobsEndpoint}/$jobOrResumeId',
          token: token,
        );
        final status = jobResp['status']?.toString().toLowerCase();
        final optimizedResumeId = jobResp['optimized_resume_id']?.toString();

        if (status == 'completed' &&
            optimizedResumeId != null &&
            optimizedResumeId.isNotEmpty) {
          // Worker finished — fetch the actual optimized resume
          final resumeResp = await _apiService.get(
            '${AppConstants.resumesEndpoint}/optimized/$optimizedResumeId',
            token: token,
          );
          return Resume.fromJson(resumeResp);
        }
        // Job still queued/processing — wait for next cycle
        continue;
      } catch (_) {
        // Not a job ID — fall through to legacy resume-ID strategies
      }

      // ── 2. Direct optimized resume endpoint (legacy: id is already resume id) ──
      try {
        final response = await _apiService.get(
          '${AppConstants.resumesEndpoint}/optimized/$jobOrResumeId',
          token: token,
        );
        if (_resumeIsComplete(response)) {
          return Resume.fromJson(response);
        }
      } catch (_) {}

      // ── 3. List endpoint fallback ────────────────────────────────────────
      try {
        final listResp = await _apiService.getRaw(
          '${AppConstants.resumesEndpoint}/optimized',
          token: token,
        );
        if (listResp is List) {
          final match = listResp
              .whereType<Map<String, dynamic>>()
              .where((r) => (r['id'] ?? r['ID'])?.toString() == jobOrResumeId)
              .firstOrNull;
          if (match != null && _resumeIsComplete(match)) {
            return Resume.fromJson(match);
          }
        }
      } catch (_) {}
    }
    throw Exception('Optimization timed out after ${maxAttempts * interval.inSeconds}s');
  }

  /// Returns true when a raw JSON response represents a fully-processed resume.
  bool _resumeIsComplete(Map<String, dynamic> r) {
    final status = r['status']?.toString().toLowerCase();
    final stillPending = status == 'processing' ||
        status == 'pending' ||
        status == 'queued' ||
        status == 'started' ||
        status == 'running';
    if (stillPending) return false;

    // Check all known locations for score/suggestions/text
    final score = r['score'] ?? r['match_score'] ?? r['MatchScore'];
    final hasScore = score != null && (score is! num || score > 0);
    final optimizedText = r['optimized_text'] ?? r['optimized_content'] ?? r['OptimizedContent'];
    final hasText = optimizedText is String && optimizedText.isNotEmpty;
    final rawSuggestions = r['suggestions'] ?? r['Suggestions'];
    final hasSuggestions = rawSuggestions is List && rawSuggestions.isNotEmpty;
    final pd = r['parsed_data'] ?? r['ParsedData'];
    final hasNestedScore = pd is Map &&
        (pd['score'] != null || pd['match_score'] != null) &&
        (pd['score'] is! num || (pd['score'] as num) > 0);
    final hasNestedSuggestions =
        pd is Map && pd['suggestions'] is List && (pd['suggestions'] as List).isNotEmpty;

    return hasScore || hasText || hasSuggestions || hasNestedScore || hasNestedSuggestions;
  }

  /// Single-shot fetch for a completed optimization.
  /// Tries the job-status endpoint first (id may be a job_id), then falls back
  /// to the optimized-resume endpoint. Returns null on any error.
  Future<Resume?> fetchCompletedOptimization(String id) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return null;

      // 1. Try job-status endpoint — id might be a job_id
      try {
        final jobResp = await _apiService.get(
          '${AppConstants.optimizeJobsEndpoint}/$id',
          token: token,
        );
        final status = jobResp['status']?.toString().toLowerCase();
        final optimizedResumeId = jobResp['optimized_resume_id']?.toString();
        if (status == 'completed' &&
            optimizedResumeId != null &&
            optimizedResumeId.isNotEmpty) {
          final resumeResp = await _apiService.get(
            '${AppConstants.resumesEndpoint}/optimized/$optimizedResumeId',
            token: token,
          );
          return Resume.fromJson(resumeResp);
        }
      } catch (_) {}

      // 2. Try direct optimized-resume endpoint — id might already be the resume id
      try {
        final resumeResp = await _apiService.get(
          '${AppConstants.resumesEndpoint}/optimized/$id',
          token: token,
        );
        if (_resumeIsComplete(resumeResp)) {
          return Resume.fromJson(resumeResp);
        }
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  Future<String> startLinkedInOptimize({required String resumeId}) async {
    final pushReady =
        await _notificationService.ensurePushRegistrationForCurrentSession();
    if (!pushReady) {
      throw Exception(
        'Push notifications are not ready for this session yet. Please try again in a moment.',
      );
    }

    final token = await _storageService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiService.post(
      AppConstants.linkedinOptimizeEndpoint,
      {'resume_id': resumeId},
      token: token,
    );

    final jobId = response['job_id']?.toString() ?? response['id']?.toString();
    if (jobId == null) throw Exception('No job_id in LinkedIn optimize response');
    return jobId;
  }

  /// Polls the job status until completed or failed (max ~2 min).
  Future<LinkedInOptimizedData> pollLinkedInJob(String jobId) async {
    final token = await _storageService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    const maxAttempts = 24;
    const interval = Duration(seconds: 5);

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);

      final jobResponse = await _apiService.get(
        '${AppConstants.optimizeJobsEndpoint}/$jobId',
        token: token,
      );

      final status = jobResponse['status']?.toString().toLowerCase();

      if (status == 'failed' || status == 'error') {
        throw Exception('LinkedIn optimization job failed');
      }

      if (status == 'completed') {
        // The job response may contain the full optimized resume payload
        if (jobResponse['parsed_data'] != null) {
          return LinkedInOptimizedData.fromJson(jobResponse);
        }

        // The individual endpoint is deprecated – use the list endpoint and filter by ID
        final optimizedResumeId =
            jobResponse['optimized_resume_id']?.toString() ??
            jobResponse['id']?.toString();

        final listResponse = await _apiService.getRaw(
          '${AppConstants.resumesEndpoint}/optimized',
          token: token,
        );

        if (listResponse is List && listResponse.isNotEmpty) {
          final items = listResponse.cast<Map<String, dynamic>>();

          // Try to match by ID first
          if (optimizedResumeId != null) {
            final match = items.where(
              (r) => (r['id'] ?? r['ID'])?.toString() == optimizedResumeId,
            );
            if (match.isNotEmpty) {
              return LinkedInOptimizedData.fromJson(match.first);
            }
          }

          // Fall back to the most recent LinkedIn-type entry
          final linkedInItems = items.where((r) {
            final pd = r['parsed_data'] as Map?;
            final type = (r['type'] ?? r['Type'])?.toString();
            return type == 'linkedin' ||
                pd != null && pd['type']?.toString() == 'linkedin';
          });
          if (linkedInItems.isNotEmpty) {
            return LinkedInOptimizedData.fromJson(linkedInItems.last);
          }
        }

        throw Exception('Could not find completed LinkedIn optimization');
      }
    }

    throw Exception('LinkedIn optimization timed out');
  }

  /// Uploads a PDF file to the backend for AI parsing.
  /// Returns a [Resume] pre-populated with the extracted data.
  Future<Resume> parsePdfResume({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    final token = await _authService.ensureFreshAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiService.postMultipart(
      AppConstants.parsePdfResumeEndpoint,
      'file',
      pdfBytes,
      fileName,
      token: token,
    );

    return Resume.fromJson(response);
  }

  /// Same as [parsePdfResume] but also returns the ATS score extracted from the
  /// raw response, so callers can display it before opening the edit form.
  Future<({Resume resume, int atsScore})> parsePdfResumeWithScore({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    final token = await _authService.ensureFreshAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiService.postMultipart(
      AppConstants.parsePdfResumeEndpoint,
      'file',
      pdfBytes,
      fileName,
      token: token,
    );

    final parsed = response['parsed_data'] as Map<String, dynamic>? ?? response;
    final rawScore = parsed['score'] ?? parsed['ats_score'] ?? response['score'];
    final atsScore = (rawScore is num ? rawScore.round() : 0).clamp(0, 100);

    return (resume: Resume.fromJson(response), atsScore: atsScore);
  }

  Future<Resume> createManualResume({
    required Map<String, dynamic> resumeData,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _apiService.post(
        AppConstants.createManualResumeEndpoint,
        resumeData,
        token: token,
      );

      return Resume.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create manual resume: $e');
    }
  }

  Future<List<Resume>> getResumes() async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return [];


      final response = await _apiService.getRaw(
        AppConstants.resumesEndpoint,
        token: token,
      );


      final optimizedResponse = await _apiService.getRaw(
        '${AppConstants.resumesEndpoint}/optimized',
        token: token,
      );


      final List<dynamic> rawResumes = [];
      if (response is List) {
        rawResumes.addAll(response);
      }
      if (optimizedResponse is List) {
        rawResumes.addAll(optimizedResponse);
      }


      if (rawResumes.isEmpty) return [];

      final resumes = rawResumes.map((json) => Resume.fromJson(json)).toList();

      return resumes;
    } catch (e) {
      return [];
    }
  }

  Future<Resume?> getResumeById(String resumeId, {String? type}) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return null;

      // Usar endpoint específico baseado no tipo do currículo
      String endpoint;
      if (type == 'manual') {
        endpoint = '${AppConstants.createManualResumeEndpoint}/$resumeId';
      } else {
        // Para otimizados ou quando tipo não especificado
        endpoint = '${AppConstants.resumesEndpoint}/optimized/$resumeId';
      }

      try {
        final response = await _apiService.get(
          endpoint,
          token: token,
        );


        final resume = Resume.fromJson(response);
        
        return resume;
      } catch (endpointError) {
        rethrow;
      }
    } catch (e) {
      throw Exception('Failed to get resume: $e');
    }
  }

  Future<void> deleteResume(String resumeId, {String? type}) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Usar endpoint padrão para deletar ambos os tipos
      final endpoint = '${AppConstants.resumesEndpoint}/$resumeId';


      await _apiService.delete(
        endpoint,
        token: token,
      );
    } catch (e) {
      throw Exception('Failed to delete resume: $e');
    }
  }

  Future<Resume> updateManualResume({
    required String resumeId,
    required Map<String, dynamic> resumeData,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _apiService.put(
        '${AppConstants.createManualResumeEndpoint}/$resumeId',
        resumeData,
        token: token,
      );

      return Resume.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update manual resume: $e');
    }
  }

  Future<Resume> updateOptimizedResume({
    required String resumeId,
    required Map<String, dynamic> resumeData,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }


      final response = await _apiService.put(
        '${AppConstants.resumesEndpoint}/optimized/$resumeId',
        resumeData,
        token: token,
      );

      return Resume.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update optimized resume: $e');
    }
  }
}
