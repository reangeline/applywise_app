import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/contact.dart';
import '../models/job_application.dart';
import '../models/pipeline_analytics.dart';
import 'api_service.dart';
import 'storage_service.dart';

class CreateJobRequest {
  final String companyName;
  final String jobTitle;
  final String location;
  final String stage;
  final String resumeId;
  final int atsScore;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final String jobDescription;
  final String jobUrl;
  final bool isArchived;

  const CreateJobRequest({
    required this.companyName,
    required this.jobTitle,
    this.location = '',
    this.stage = 'applied',
    this.resumeId = '',
    this.atsScore = 0,
    this.matchedKeywords = const [],
    this.missingKeywords = const [],
    this.jobDescription = '',
    this.jobUrl = '',
    this.isArchived = false,
  });

  Map<String, dynamic> toJson() => {
        'company_name': companyName,
        'job_title': jobTitle,
        'location': location,
        'stage': stage,
        'resume_id': resumeId,
        'ats_score': atsScore,
        'matched_keywords': matchedKeywords,
        'missing_keywords': missingKeywords,
        'job_description': jobDescription,
        'job_url': jobUrl,
        'is_archived': isArchived,
      };
}

class PipelineService {
  static const _cacheKey = 'pipeline_jobs_cache';
  static const _analyticsCacheKey = 'pipeline_analytics_cache';

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<String> _token() async {
    final t = await _storage.getAccessToken();
    if (t == null) throw Exception('Not authenticated');
    return t;
  }

  Map<String, dynamic> _unwrapJobResponse(Map<String, dynamic> response) {
    final nested = response['data'];
    if (nested is Map<String, dynamic>) return nested;
    return response;
  }

  Future<List<JobApplication>> fetchJobs() async {
    try {
      final token = await _token();
      final data = await _api.getRaw(AppConstants.pipelineEndpoint, token: token);
      final jobsJson = data as List<dynamic>? ?? [];
      debugPrint('🌐 fetchJobs raw type: ${data.runtimeType}');
      debugPrint('🌐 fetchJobs: ${jobsJson.length} jobs from server: ${jobsJson.map((j) => (j as Map)['id']).toList()}');
      final jobs = jobsJson
          .map((j) => JobApplication.fromApiJson(j as Map<String, dynamic>))
          .toList();

      // Save to cache for offline fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(jobs.map((j) => j.toJson()).toList()),
      );

      return jobs;
    } catch (e) {
      // Try offline cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List<dynamic>;
        return list
            .map((j) => JobApplication.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  Future<JobApplication> createJob(CreateJobRequest req) async {
    final token = await _token();
    final response = await _api.post(
      AppConstants.pipelineEndpoint,
      req.toJson(),
      token: token,
    );
    final data = _unwrapJobResponse(response);
    await _invalidateCache();
    final job = JobApplication.fromApiJson(data);
    if (job.id.trim().isEmpty) {
      throw Exception('Pipeline job was created without a valid id');
    }
    return job;
  }

  Future<JobApplication> updateJob(
      String jobId, Map<String, dynamic> fields) async {
    final token = await _token();
    final response = await _api.put(
      '${AppConstants.pipelineEndpoint}/$jobId',
      fields,
      token: token,
    );
    final data = _unwrapJobResponse(response);
    return JobApplication.fromApiJson(data);
  }

  Future<void> deleteJob(String jobId) async {
    final token = await _token();
    await _api.delete(
      '${AppConstants.pipelineEndpoint}/$jobId',
      token: token,
    );
    await _invalidateCache();
  }

  /// Moves a job to a new stage via PUT /pipeline/{id}.
  /// Optional [extra] fields (e.g. offer_amount, rejection_feedback) are merged.
  Future<JobApplication> moveToStage(String jobId, String stage,
      {Map<String, dynamic>? extra}) async {
    final token = await _token();
    final normalizedJobId = jobId.trim();
    if (normalizedJobId.isEmpty) {
      throw Exception('Cannot move pipeline job without a valid id');
    }
    final body = <String, dynamic>{'stage': stage.toLowerCase(), ...?extra};
    final response = await _api.put(
      '${AppConstants.pipelineEndpoint}/$normalizedJobId',
      body,
      token: token,
    );
    final data = _unwrapJobResponse(response);
    await _invalidateCache();
    return JobApplication.fromApiJson(data);
  }

  Future<JobApplication> logInterview(
    String jobId,
    DateTime interviewAt,
    String interviewType,
  ) async {
    final normalizedJobId = jobId.trim();
    if (normalizedJobId.isEmpty) {
      throw Exception('Cannot log interview without a valid job id');
    }
    final token = await _token();
    final response = await _api.post(
      '${AppConstants.pipelineEndpoint}/$normalizedJobId/interview',
      {
        'interview_at': interviewAt.toIso8601String(),
        'interview_type': interviewType,
      },
      token: token,
    );
    final data = _unwrapJobResponse(response);
    final job = JobApplication.fromApiJson(data);
    if (job.id.trim().isEmpty) {
      throw Exception('Interview was saved but the response did not include a valid job id');
    }
    return job;
  }

  Future<JobApplication> logFollowUp(
    String jobId,
    String channel,
    String message,
  ) async {
    final token = await _token();
    final response = await _api.post(
      '${AppConstants.pipelineEndpoint}/$jobId/followup',
      {
        'channel': channel,
        'message': message,
      },
      token: token,
    );
    final data = _unwrapJobResponse(response);
    return JobApplication.fromApiJson(data);
  }

  /// Calls the AI coach endpoint and returns the generated [content] string.
  /// Results are cached in-memory by jobId+stage to avoid redundant API calls.
  static final Map<String, String> _coachCache = {};
  static String _coachCacheKey(String jobId, String stage) => '${jobId}_$stage';
  static String? getCachedCoach(String jobId, String stage) =>
      _coachCache[_coachCacheKey(jobId, stage)];
  static void setCachedCoach(String jobId, String stage, String content) =>
      _coachCache[_coachCacheKey(jobId, stage)] = content;

  static void clearCachedCoach(String jobId, String stage) =>
      _coachCache.remove(_coachCacheKey(jobId, stage));

  static Future<void> clearAllCaches() async {
    _coachCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_analyticsCacheKey);
  }

  Future<String> generateCoachContent({
    required String jobId,
    required String stage,
    required String jobTitle,
    required String companyName,
    String? location,
    int atsScore = 0,
    String resumeVersion = '',
    String jobDescription = '',
    String jobUrl = '',
    List<String> matchedKeywords = const [],
    List<String> missingKeywords = const [],
    int daysSinceApplied = 0,
    String tone = 'default',
  }) async {
    final token = await _token();
    final endpoint = '${AppConstants.pipelineCoachEndpoint}/$jobId/coach';
    final data = await _api.post(
      endpoint,
      {
        'stage': stage,
        'job_title': jobTitle,
        'company_name': companyName,
        'location': location,
        'ats_score': atsScore,
        'resume_version': resumeVersion,
        'job_description': jobDescription,
        'job_url': jobUrl,
        'matched_keywords': matchedKeywords,
        'missing_keywords': missingKeywords,
        'days_since_applied': daysSinceApplied,
        'tone': tone,
      },
      token: token,
    );
    final content = data['content'] as String? ?? '';
    PipelineService.setCachedCoach(jobId, stage, content);
    return content;
  }

  Future<void> _invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  // ─── Contacts ───────────────────────────────────────────────────────────────

  Future<List<Contact>> fetchContacts(String jobId) async {
    final token = await _token();
    final data = await _api.getRaw(
      '${AppConstants.pipelineEndpoint}/$jobId/contacts',
      token: token,
    );
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else {
      list = (data as Map<String, dynamic>)['contacts'] as List? ?? [];
    }
    return list
        .map((c) => Contact.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Contact> addContact(String jobId,
      {required String name,
      String role = '',
      String linkedinUrl = '',
      String email = '',
      String notes = ''}) async {
    final token = await _token();
    final data = await _api.post(
      '${AppConstants.pipelineEndpoint}/$jobId/contacts',
      {
        'name': name,
        if (role.isNotEmpty) 'role': role,
        if (linkedinUrl.isNotEmpty) 'linkedinUrl': linkedinUrl,
        if (email.isNotEmpty) 'email': email,
        if (notes.isNotEmpty) 'notes': notes,
      },
      token: token,
    );
    return Contact.fromJson(data);
  }

  Future<void> deleteContact(String jobId, String contactId) async {
    final token = await _token();
    await _api.delete(
      '${AppConstants.pipelineEndpoint}/$jobId/contacts/$contactId',
      token: token,
    );
  }

  Future<PipelineAnalytics> fetchAnalytics() async {
    try {
      final token = await _token();
      final data = await _api.get(
        '${AppConstants.pipelineEndpoint}/analytics',
        token: token,
      );
      final analytics = PipelineAnalytics.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_analyticsCacheKey, jsonEncode(analytics.toJson()));
      return analytics;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_analyticsCacheKey);
      if (cached != null) {
        return PipelineAnalytics.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
      }
      rethrow;
    }
  }
}
