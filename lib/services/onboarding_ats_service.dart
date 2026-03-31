import '../config/constants.dart';
import '../models/onboarding_models.dart';
import 'api_service.dart';

/// Handles the pre-authentication ATS analysis calls.
///
/// Both methods call [AppConstants.parsePdfResumeEndpoint] without a token so
/// the user does not need an account at this stage.  After sign-up the
/// [associateWithAuth] method re-sends the original data with the user's
/// access token so the backend can persist it linked to the new account.
class OnboardingAtsService {
  final ApiService _apiService = ApiService();

  // ─── Unauthenticated analysis ─────────────────────────────────────────────

  Future<OnboardingAtsResult> analyzeWithPdf({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    final response = await _apiService.postMultipart(
      AppConstants.parsePdfResumeEndpoint,
      'file',
      pdfBytes,
      fileName,
      // No token — unauthenticated call
    );
    return _parseResponse(response);
  }

  Future<OnboardingAtsResult> analyzeWithText({
    required String resumeText,
  }) async {
    final response = await _apiService.post(
      AppConstants.parsePdfResumeEndpoint,
      {'resume_text': resumeText},
      // No token — unauthenticated call
    );
    return _parseResponse(response);
  }

  // ─── Post-auth association ────────────────────────────────────────────────

  /// Re-sends the original resume data with the authenticated user's token so
  /// the backend links the analysis to the newly created account.
  /// Errors are swallowed — this step is non-fatal.
  Future<void> associateWithAuth({
    required String token,
    List<int>? pdfBytes,
    String? pdfFileName,
    String? resumeText,
  }) async {
    try {
      if (pdfBytes != null && pdfFileName != null) {
        await _apiService.postMultipart(
          AppConstants.parsePdfResumeEndpoint,
          'file',
          pdfBytes,
          pdfFileName,
          token: token,
        );
      } else if (resumeText != null) {
        await _apiService.post(
          AppConstants.parsePdfResumeEndpoint,
          {'resume_text': resumeText},
          token: token,
        );
      }
    } catch (_) {
      // Non-fatal: the user can still proceed even if association fails.
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  OnboardingAtsResult _parseResponse(Map<String, dynamic> response) {
    // The backend may return the score at the top level or inside parsed_data.
    final parsed =
        response['parsed_data'] as Map<String, dynamic>? ?? response;

    final rawScore =
        parsed['score'] ?? parsed['ats_score'] ?? response['score'];
    final score = (rawScore is num ? rawScore.round() : 0).clamp(0, 100);

    final suggestions =
        _extractList(parsed, 'suggestions') + _extractList(response, 'suggestions');
    final missing = _extractList(parsed, 'missing_requirements') +
        _extractList(response, 'missing_requirements');

    // Deduplicate
    final allIssues = {...suggestions, ...missing}.toList();
    final totalIssues = allIssues.length;

    // Build human-readable problem categories
    final List<String> categories = [];
    if (missing.isNotEmpty) categories.add('Missing keywords');
    if (allIssues.any((s) {
      final l = s.toLowerCase();
      return l.contains('format') || l.contains('section') || l.contains('seç');
    })) {
      categories.add('Formatting');
    }
    final missingSections = _extractList(parsed, 'missing_sections') +
        _extractList(response, 'missing_sections');
    if (missingSections.isNotEmpty) categories.add('Missing sections');
    if (suggestions.isNotEmpty && !categories.contains('Content')) {
      categories.add('Content');
    }
    // Fallback when the backend returns no detail
    if (categories.isEmpty && totalIssues > 0) {
      categories.addAll(['Keywords', 'Formatting', 'Missing sections']);
    } else if (categories.isEmpty) {
      categories.addAll(['Keywords', 'Formatting', 'Missing sections']);
    }

    return OnboardingAtsResult(
      score: score,
      totalIssues: totalIssues,
      problemCategories: categories,
      rawData: response,
    );
  }

  List<String> _extractList(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
