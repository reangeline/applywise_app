import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_application.dart';
import '../models/resume.dart';
import '../services/pipeline_service.dart';
import '../services/resume_service.dart';

// ─── PendingJob ───────────────────────────────────────────────────────────────

/// Holds the context of an optimization that was started but not yet confirmed
/// into the pipeline (e.g. user pressed back on AddJobConfirmScreen).
class PendingJob {
  final String id;
  final String company;
  final String role;
  final String? location;
  final String? resumeId;
  final String resumeLabel;
  /// The [Resume] returned immediately by the optimize POST. May have no score
  /// yet — [AddJobConfirmScreen] will poll until it arrives.
  final Resume? optimizedResume;

  const PendingJob({
    required this.id,
    required this.company,
    required this.role,
    this.location,
    this.resumeId,
    required this.resumeLabel,
    this.optimizedResume,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
        'company': company,
        'role': role,
        'location': location,
        'resumeId': resumeId,
        'resumeLabel': resumeLabel,
        'optimizedResume': optimizedResume?.toJson(),
      };

  factory PendingJob.fromJson(Map<String, dynamic> json) => PendingJob(
    id: json['id'] as String? ?? _newPendingJobId(),
        company: json['company'] as String,
        role: json['role'] as String,
        location: json['location'] as String?,
        resumeId: json['resumeId'] as String?,
        resumeLabel: json['resumeLabel'] as String,
        optimizedResume: json['optimizedResume'] != null
            ? Resume.fromJson(json['optimizedResume'] as Map<String, dynamic>)
            : null,
      );
}

const _logoPalette = [
  (Color(0xFFE6F1FB), Color(0xFF185FA5)),
  (Color(0xFFFBEAF0), Color(0xFF993556)),
  (Color(0xFFEAF3DE), Color(0xFF3B6D11)),
  (Color(0xFFFAEEDA), Color(0xFF854F0B)),
  (Color(0xFFE1F5EE), Color(0xFF085041)),
  (Color(0xFFEEEDFE), Color(0xFF534AB7)),
];

const _kJobsKey = 'pipeline_jobs_v1';
const _kPendingJobKey = 'pipeline_pending_job_v1';

String _newPendingJobId() => DateTime.now().microsecondsSinceEpoch.toString();

class PipelineProvider extends ChangeNotifier {
  final List<JobApplication> _jobs = [];
  bool _loaded = false;
  bool _fetching = false;

  final List<PendingJob> _pendingJobs = [];
  List<PendingJob> get pendingJobs => List.unmodifiable(_pendingJobs);
  bool get isLoaded => _loaded;
  bool get isFetching => _fetching;

  String _normalizePendingText(String value) => value.trim().toLowerCase();

  String? _pendingResumeIdentity(PendingJob job) =>
      job.optimizedResume?.id ?? job.resumeId;

  List<String> _pendingLookupIds(PendingJob job) {
    final ids = <String>{
      if (job.resumeId != null && job.resumeId!.isNotEmpty) job.resumeId!,
      if (job.optimizedResume?.id != null && job.optimizedResume!.id.isNotEmpty)
        job.optimizedResume!.id,
    };
    return ids.toList();
  }

  bool _jobMatchesPending(JobApplication job, PendingJob pendingJob) {
    final pendingResumeId = _pendingResumeIdentity(pendingJob);
    if (pendingResumeId != null && pendingResumeId.isNotEmpty) {
      if (job.resumeId == pendingResumeId ||
          job.optimizedResumeId == pendingResumeId) {
        return true;
      }
    }

    final sameCompany =
        _normalizePendingText(job.companyName) == _normalizePendingText(pendingJob.company);
    final sameRole =
        _normalizePendingText(job.jobTitle) == _normalizePendingText(pendingJob.role);
    if (!sameCompany || !sameRole) return false;

    final pendingLocation = pendingJob.location;
    if (pendingLocation == null || pendingLocation.isEmpty) return true;

    final jobLocation = job.location;
    if (jobLocation == null || jobLocation.isEmpty) return true;

    return _normalizePendingText(jobLocation) ==
        _normalizePendingText(pendingLocation);
  }

  bool _pruneConfirmedPendingJobs() {
    if (_pendingJobs.isEmpty || _jobs.isEmpty) return false;

    final before = _pendingJobs.length;
    _pendingJobs.removeWhere(
      (pendingJob) => _jobs.any((job) => _jobMatchesPending(job, pendingJob)),
    );
    final changed = _pendingJobs.length != before;
    if (changed) {
      debugPrint(
        '🧹 pruned ${before - _pendingJobs.length} confirmed pending jobs; ${_pendingJobs.length} remain',
      );
    }
    return changed;
  }

  String _jobFallbackKey(JobApplication job) {
    final resumeId = (job.resumeId ?? job.optimizedResumeId ?? '').trim().toLowerCase();
    final company = _normalizePendingText(job.companyName);
    final role = _normalizePendingText(job.jobTitle);
    final location = _normalizePendingText(job.location ?? '');
    return '$company|$role|$location|$resumeId';
  }

  int _stageRank(String stage) {
    switch (stage.trim().toLowerCase()) {
      case 'wishlist':
        return 0;
      case 'applied':
        return 1;
      case 'interview':
        return 2;
      case 'offer':
        return 3;
      case 'accepted':
        return 4;
      case 'rejected':
        return 4;
      default:
        return -1;
    }
  }

  bool _dedupeJobs() {
    if (_jobs.length < 2) return false;

    final byId = <String, JobApplication>{};
    final byFallback = <String, JobApplication>{};
    final ordered = <JobApplication>[];

    for (final job in _jobs) {
      if (job.id.isNotEmpty) {
        byId[job.id] = job;
      } else {
        byFallback[_jobFallbackKey(job)] = job;
      }
    }

    final seenIds = <String>{};
    final seenFallbacks = <String>{};
    for (final job in _jobs.reversed) {
      if (job.id.isNotEmpty) {
        final preferred = byId[job.id]!;
        if (!seenIds.add(preferred.id)) continue;
        ordered.add(preferred);
        continue;
      }

      final key = _jobFallbackKey(job);
      final preferred = byFallback[key]!;
      if (!seenFallbacks.add(key)) continue;
      ordered.add(preferred);
    }

    final deduped = ordered.reversed.toList();
    final changed = deduped.length != _jobs.length;
    if (changed) {
      debugPrint('🧹 deduped jobs from ${_jobs.length} to ${deduped.length}');
      _jobs
        ..clear()
        ..addAll(deduped);
    }
    return changed;
  }

  /// Call once after the app starts (before showing the pipeline UI).
  /// Restores from local cache immediately for instant UI.
  Future<void> load() async {
    debugPrint('🔵 PipelineProvider.load() called — stack: ${StackTrace.current.toString().split("\n").take(4).join(" | ")}');
    final prefs = await SharedPreferences.getInstance();

    // ── jobs — cache first for instant UI ─────────────────────────────────
    final jobsJson = prefs.getString(_kJobsKey);
    if (jobsJson != null) {
      try {
        final list = jsonDecode(jobsJson) as List<dynamic>;
        _jobs.clear();
        _jobs.addAll(
          list.map((e) => JobApplication.fromJson(e as Map<String, dynamic>)),
        );
        _dedupeJobs();
        debugPrint('🔵 load() restored ${_jobs.length} jobs: ${_jobs.map((j) => "${j.companyName}(${j.id})").join(", ")}');
      } catch (_) {} // corrupt data — start empty
    }

    // ── pending jobs ──────────────────────────────────────────────────────
    final pendingJson = prefs.getString(_kPendingJobKey);
    if (pendingJson != null) {
      try {
        final decoded = jsonDecode(pendingJson);
        _pendingJobs
          ..clear()
          ..addAll(
            switch (decoded) {
              List<dynamic>() => decoded
                  .map((e) => PendingJob.fromJson(e as Map<String, dynamic>)),
              Map<String, dynamic>() => [PendingJob.fromJson(decoded)],
              _ => const <PendingJob>[],
            },
          );
      } catch (_) {}
    }

    _pruneConfirmedPendingJobs();
    _savePendingJobs();

    _loaded = true;
    notifyListeners();
    await refreshPendingOptimizations();
  }

  /// Pull fresh jobs from the backend and merge into local state.
  /// Called on explicit pull-to-refresh — never automatically.
  Future<void> refresh() {
    debugPrint('🔄 refresh() called — stack:\n${StackTrace.current.toString().split("\n").take(6).join("\n")}');
    return _fetchFromBackend();
  }

  List<JobApplication> get jobs => List.unmodifiable(_jobs);

  Future<void> _fetchFromBackend() async {
    if (_fetching) return;
    _fetching = true;
    notifyListeners();
    debugPrint('🔴 _fetchFromBackend() START — local _jobs.length=${_jobs.length}: ${_jobs.map((j) => "${j.companyName}(${j.id})").join(", ")}');
    debugPrint('🔴 _fetchFromBackend caller: ${StackTrace.current.toString().split("\n").take(4).join(" | ")}');
    try {
      final serverJobs = await PipelineService().fetchJobs();

      // Merge strategy: server wins for existing IDs; local-only jobs are kept.
      final serverMap = <String, JobApplication>{
        for (final j in serverJobs) if (j.id.isNotEmpty) j.id: j,
      };
      final localMap = <String, JobApplication>{
        for (final j in _jobs) if (j.id.isNotEmpty) j.id: j,
      };

      final merged = <JobApplication>[];

      // 1. All server jobs — prefer local display fields (initials, colors, resumeVersion)
      for (final serverJob in serverJobs) {
        final local = localMap[serverJob.id];
        if (local != null) {
          final keepLocalStage =
              _stageRank(local.stage) > _stageRank(serverJob.stage);
          merged.add(JobApplication(
            id: serverJob.id,
            companyInitials: local.companyInitials.isNotEmpty
                ? local.companyInitials
                : serverJob.companyInitials,
            logoBackground: local.logoBackground,
            logoTextColor: local.logoTextColor,
            jobTitle: serverJob.jobTitle.isNotEmpty ? serverJob.jobTitle : local.jobTitle,
            companyName: serverJob.companyName.isNotEmpty ? serverJob.companyName : local.companyName,
            dateApplied: local.dateApplied.isNotEmpty ? local.dateApplied : serverJob.dateApplied,
            resumeVersion: local.resumeVersion,
            atsScore: serverJob.atsScore > 0 ? serverJob.atsScore : local.atsScore,
            stage: keepLocalStage ? local.stage : serverJob.stage,
            opacity: local.opacity,
            resumeId: serverJob.resumeId ?? local.resumeId,
            optimizedResumeId: serverJob.optimizedResumeId ?? local.optimizedResumeId,
            location: serverJob.location ?? local.location,
            archived: serverJob.archived,
            interviewAt: serverJob.interviewAt ?? local.interviewAt,
            interviewType: serverJob.interviewType.isNotEmpty
                ? serverJob.interviewType
                : local.interviewType,
            timeline: serverJob.timeline.isNotEmpty ? serverJob.timeline : local.timeline,
            jobDescription: serverJob.jobDescription.isNotEmpty
                ? serverJob.jobDescription
                : local.jobDescription,
            jobUrl: serverJob.jobUrl.isNotEmpty ? serverJob.jobUrl : local.jobUrl,
            matchedKeywords: serverJob.matchedKeywords.isNotEmpty
                ? serverJob.matchedKeywords
                : local.matchedKeywords,
            missingKeywords: serverJob.missingKeywords.isNotEmpty
                ? serverJob.missingKeywords
                : local.missingKeywords,
          ));
        } else {
          merged.add(serverJob);
        }
      }

      // 2. Keep local jobs not yet confirmed on server (just added this session)
      for (final local in _jobs) {
        if (!serverMap.containsKey(local.id)) {
          merged.add(local);
        }
      }

      // Safety: never wipe local jobs if the server returned nothing useful.
      final toSave = merged.isNotEmpty ? merged : _jobs.toList();
      final before = _jobs.length;
      _jobs
        ..clear()
        ..addAll(toSave);
      _dedupeJobs();
      _pruneConfirmedPendingJobs();
      if (_jobs.length < before) {
        debugPrint('🚨 _fetchFromBackend SHRUNK _jobs from $before → ${_jobs.length}!');
        debugPrint('🚨 serverJobs ids: ${serverJobs.map((j) => j.id).toList()}');
        debugPrint('🚨 merged ids: ${toSave.map((j) => "${j.companyName}(${j.id})").toList()}');
      }
      debugPrint('🔴 _fetchFromBackend() DONE — _jobs.length=${_jobs.length}: ${_jobs.map((j) => "${j.companyName}(${j.id})").join(", ")}');
      await _saveJobs();
    } catch (e) {
      debugPrint('🔴 _fetchFromBackend() ERROR: $e');
      // Network/auth error — keep whatever is in cache
    } finally {
      _fetching = false;
      notifyListeners();
    }
  }

  Future<void> _saveJobs() async {
    // Snapshot synchronously before any await so concurrent mutations to _jobs
    // (e.g. a merge from _fetchFromBackend) don't corrupt the persisted data.
    final snapshot = jsonEncode(_jobs.map((j) => j.toJson()).toList());
    debugPrint('💾 _saveJobs: saving ${_jobs.length} jobs: ${_jobs.map((j) => "${j.companyName}(${j.id})").join(", ")}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kJobsKey, snapshot);
  }

  Future<void> _savePendingJobs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_pendingJobs.isEmpty) {
      await prefs.remove(_kPendingJobKey);
    } else {
      await prefs.setString(
        _kPendingJobKey,
        jsonEncode(_pendingJobs.map((job) => job.toJson()).toList()),
      );
    }
  }

  PendingJob addPendingJob(PendingJob job) {
    final pendingJob = job.id.isEmpty
        ? PendingJob(
            id: _newPendingJobId(),
            company: job.company,
            role: job.role,
            location: job.location,
            resumeId: job.resumeId,
            resumeLabel: job.resumeLabel,
            optimizedResume: job.optimizedResume,
          )
        : job;
    debugPrint('🟣 addPendingJob(${pendingJob.company}) — _jobs.length=${_jobs.length}, _pendingJobs.length=${_pendingJobs.length + 1}');
    _pendingJobs.add(pendingJob);
    _savePendingJobs();
    notifyListeners();
    return pendingJob;
  }

  void removePendingJob(String pendingJobId) {
    debugPrint('🟡 removePendingJob($pendingJobId) — _jobs.length=${_jobs.length}, _pendingJobs.length=${_pendingJobs.length}');
    _pendingJobs.removeWhere((job) => job.id == pendingJobId);
    _savePendingJobs();
    notifyListeners();
  }

  /// Called when the background optimization worker finishes. Updates the
  /// cached [PendingJob.optimizedResume] so reopening the card skips polling.
  void updatePendingJobResume(String pendingJobId, Resume resume) {
    final index = _pendingJobs.indexWhere((job) => job.id == pendingJobId);
    if (index < 0) return;
    final pendingJob = _pendingJobs[index];
    _pendingJobs[index] = PendingJob(
      id: pendingJob.id,
      company: pendingJob.company,
      role: pendingJob.role,
      location: pendingJob.location,
      resumeId: resume.id.isNotEmpty ? resume.id : pendingJob.resumeId,
      resumeLabel: pendingJob.resumeLabel,
      optimizedResume: resume,
    );
    _savePendingJobs();
    notifyListeners();
  }

  void updatePendingJobResumeByResumeId(String resumeId, Resume resume) {
    final index = _pendingJobs.indexWhere((job) =>
        job.resumeId == resumeId || job.optimizedResume?.id == resumeId);
    if (index < 0) return;
    updatePendingJobResume(_pendingJobs[index].id, resume);
  }

  bool updatePendingJobResumeByAnyId(Iterable<String> ids, Resume resume) {
    final lookupIds = ids.where((id) => id.isNotEmpty).toSet();
    if (lookupIds.isEmpty) return false;

    final index = _pendingJobs.indexWhere(
      (job) => _pendingLookupIds(job).any(lookupIds.contains),
    );
    if (index < 0) return false;

    updatePendingJobResume(_pendingJobs[index].id, resume);
    return true;
  }

  Future<void> refreshPendingOptimizations() async {
    final pendingToRefresh = _pendingJobs
        .where((job) => job.optimizedResume?.score == null)
        .toList(growable: false);
    if (pendingToRefresh.isEmpty) return;

    for (final pendingJob in pendingToRefresh) {
      final lookupIds = _pendingLookupIds(pendingJob);
      for (final lookupId in lookupIds) {
        try {
          final resume =
              await ResumeService().fetchCompletedOptimization(lookupId);
          if (resume != null) {
            updatePendingJobResume(pendingJob.id, resume);
            break;
          }
        } catch (_) {
          // Keep pending state; user can still open the card manually.
        }
      }
    }
  }

  PendingJob? pendingJobById(String pendingJobId) {
    for (final pendingJob in _pendingJobs) {
      if (pendingJob.id == pendingJobId) return pendingJob;
    }
    return null;
  }

  void clearAllPendingJobs() {
    _pendingJobs.clear();
    _savePendingJobs();
    notifyListeners();
  }

  List<JobApplication> jobsForStage(String stage) =>
      _jobs.where((j) => j.stage == stage && !j.archived).toList();

  List<JobApplication> get archivedJobs =>
      _jobs.where((j) => j.archived).toList();

  void archiveJob(JobApplication job) {
    final i = _jobs.indexOf(job);
    if (i < 0) return;
    _jobs[i] = job.copyWith(archived: true);
    _saveJobs();
    notifyListeners();
  }

  void unarchiveJob(JobApplication job) {
    final i = _jobs.indexOf(job);
    if (i < 0) return;
    _jobs[i] = job.copyWith(archived: false);
    _saveJobs();
    notifyListeners();
  }

  /// Updates only the ATS score for a job (e.g. after loading resume data).
  /// Skips if score is 0 or unchanged.
  void updateJobAtsScore(String jobId, int score) {
    if (score <= 0) return;
    final i = _jobs.indexWhere((j) => j.id == jobId);
    if (i < 0) return;
    final j = _jobs[i];
    if (j.atsScore == score) return;
    _jobs[i] = JobApplication(
      id: j.id,
      companyInitials: j.companyInitials,
      logoBackground: j.logoBackground,
      logoTextColor: j.logoTextColor,
      jobTitle: j.jobTitle,
      companyName: j.companyName,
      dateApplied: j.dateApplied,
      resumeVersion: j.resumeVersion,
      atsScore: score,
      stage: j.stage,
      opacity: j.opacity,
      resumeId: j.resumeId,
      optimizedResumeId: j.optimizedResumeId,
      location: j.location,
      archived: j.archived,
      interviewAt: j.interviewAt,
      interviewType: j.interviewType,
      timeline: j.timeline,
      jobDescription: j.jobDescription,
      jobUrl: j.jobUrl,
      matchedKeywords: j.matchedKeywords,
      missingKeywords: j.missingKeywords,
    );
    _saveJobs();
    notifyListeners();
  }

  void addJob(JobApplication job) {
    _jobs.add(job);
    _dedupeJobs();
    _pruneConfirmedPendingJobs();
    debugPrint('🟢 addJob(${job.companyName}, id=${job.id}) → _jobs now has ${_jobs.length}: ${_jobs.map((j) => "${j.companyName}(${j.id})").join(", ")}');
    debugPrint('🟢 addJob caller: ${StackTrace.current.toString().split("\n").take(3).join(" | ")}');
    _saveJobs();
    notifyListeners();
  }

  void addOrReplaceJob(JobApplication job) {
    final index = _jobs.indexWhere((j) => j.id == job.id && j.id.isNotEmpty);
    if (index >= 0) {
      _jobs[index] = job;
    } else {
      _jobs.add(job);
    }
    _dedupeJobs();
    _pruneConfirmedPendingJobs();
    _saveJobs();
    notifyListeners();
  }

  void updateJob(JobApplication updated) {
    var matchingIndexes = [
      for (var i = 0; i < _jobs.length; i++)
        if (_jobs[i].id == updated.id) i,
    ];
    if (matchingIndexes.isEmpty) {
      matchingIndexes = [
        for (var i = 0; i < _jobs.length; i++)
          if (_jobs[i].id.isEmpty &&
              _jobs[i].companyName == updated.companyName &&
              _jobs[i].jobTitle == updated.jobTitle)
            i,
      ];
    }
    if (matchingIndexes.isEmpty) {
      addOrReplaceJob(updated);
      return;
    }
    final existing = _jobs[matchingIndexes.last];

    // Always prefer local display fields that the backend never returns.
    // Also merge timelines and preserve atsScore when backend returns 0.
    final merged = JobApplication(
      id: updated.id,
      companyInitials: existing.companyInitials,
      logoBackground: existing.logoBackground,
      logoTextColor: existing.logoTextColor,
      jobTitle: updated.jobTitle.isNotEmpty ? updated.jobTitle : existing.jobTitle,
      companyName: updated.companyName.isNotEmpty ? updated.companyName : existing.companyName,
      dateApplied: updated.dateApplied.isNotEmpty ? updated.dateApplied : existing.dateApplied,
      resumeVersion: existing.resumeVersion,
      atsScore: updated.atsScore > 0 ? updated.atsScore : existing.atsScore,
      stage: updated.stage,
      opacity: updated.opacity,
      resumeId: updated.resumeId ?? existing.resumeId,
      optimizedResumeId: updated.optimizedResumeId ?? existing.optimizedResumeId,
      location: updated.location ?? existing.location,
      archived: updated.archived,
      interviewAt: updated.interviewAt ?? existing.interviewAt,
      interviewType: updated.interviewType.isNotEmpty ? updated.interviewType : existing.interviewType,
      timeline: updated.timeline.isNotEmpty ? updated.timeline : existing.timeline,
      jobDescription: updated.jobDescription.isNotEmpty ? updated.jobDescription : existing.jobDescription,
      jobUrl: updated.jobUrl.isNotEmpty ? updated.jobUrl : existing.jobUrl,
      matchedKeywords: updated.matchedKeywords.isNotEmpty ? updated.matchedKeywords : existing.matchedKeywords,
      missingKeywords: updated.missingKeywords.isNotEmpty ? updated.missingKeywords : existing.missingKeywords,
    );
    for (final index in matchingIndexes) {
      _jobs[index] = merged;
    }
    _dedupeJobs();
    _pruneConfirmedPendingJobs();
    _saveJobs();
    notifyListeners();
  }

  static String companyInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return name.substring(0, math.min(2, name.length)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static (Color, Color) logoColors(String name) =>
      _logoPalette[name.hashCode.abs() % _logoPalette.length];

  /// If [job] has no backend id, creates it on the backend and updates the
  /// local cache. Returns the job (with real id) ready for further API calls.
  Future<JobApplication> syncJobIfNeeded(JobApplication job) async {
    final currentJobId = job.id.trim();
    if (currentJobId.isNotEmpty) return job;
    final req = CreateJobRequest(
      companyName: job.companyName.isEmpty ? 'Company' : job.companyName,
      jobTitle: job.jobTitle.isEmpty ? 'Role' : job.jobTitle,
      location: job.location ?? '',
      stage: job.stage,
      resumeId: job.resumeId ?? '',
      atsScore: job.atsScore,
      missingKeywords: job.missingKeywords,
    );
    final saved = await PipelineService().createJob(req);
    final savedJobId = saved.id.trim();
    if (savedJobId.isEmpty) {
      throw Exception('Failed to create pipeline job id before continuing');
    }
    final updated = JobApplication(
      id: savedJobId,
      companyInitials: job.companyInitials,
      logoBackground: job.logoBackground,
      logoTextColor: job.logoTextColor,
      jobTitle: job.jobTitle,
      companyName: job.companyName,
      dateApplied: job.dateApplied,
      resumeVersion: job.resumeVersion,
      atsScore: job.atsScore,
      stage: job.stage,
      opacity: job.opacity,
      resumeId: job.resumeId,
      optimizedResumeId: job.optimizedResumeId,
      location: job.location,
      archived: job.archived,
      interviewAt: job.interviewAt,
      interviewType: job.interviewType,
      timeline: job.timeline,
      jobDescription: job.jobDescription,
      jobUrl: job.jobUrl,
      matchedKeywords: job.matchedKeywords,
      missingKeywords: job.missingKeywords,
    );
    // Replace in local cache by position (old job has empty id)
    final i = _jobs.indexWhere((j) =>
        j.id.isEmpty &&
        j.companyName == job.companyName &&
        j.jobTitle == job.jobTitle);
    if (i >= 0) {
      _jobs[i] = updated;
      _dedupeJobs();
      _pruneConfirmedPendingJobs();
      _saveJobs();
      notifyListeners();
    }
    return updated;
  }

  /// Called when a push notification signals that an optimization is complete.
  /// Fetches the finished resume and updates the pending card immediately.
  Future<void> handleOptimizationNotification(Map<String, dynamic> data) async {
    if (_pendingJobs.isEmpty) return;

    final type = data['type']?.toString() ?? '';
    // LinkedIn optimizations don't use the pending-job card — ignore
    if (type.contains('linkedin')) return;

    // Extract the best available ID from the payload
    final ids = <String>{
      data['optimized_resume_id']?.toString() ?? '',
      data['job_id']?.toString() ?? '',
      data['resume_id']?.toString() ?? '',
    }..remove('');
    if (ids.isEmpty) {
      await refreshPendingOptimizations();
      return;
    }

    try {
      for (final id in ids) {
        final resume = await ResumeService().fetchCompletedOptimization(id);
        if (resume == null) continue;

        final matched = updatePendingJobResumeByAnyId(
          [...ids, resume.id],
          resume,
        );
        if (matched) return;
      }
      await refreshPendingOptimizations();
    } catch (_) {
      await refreshPendingOptimizations();
    }
  }

  Future<void> reset() async {
    _jobs.clear();
    _pendingJobs.clear();
    _loaded = false;
    _fetching = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kJobsKey);
    await prefs.remove(_kPendingJobKey);
    await PipelineService.clearAllCaches();

    notifyListeners();
  }
}
