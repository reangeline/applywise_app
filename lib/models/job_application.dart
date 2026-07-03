import 'package:flutter/material.dart';

class TimelineEvent {
  final String id;
  final String type;
  final String label;
  final String detail;
  final DateTime createdAt;

  const TimelineEvent({
    required this.id,
    required this.type,
    required this.label,
    this.detail = '',
    required this.createdAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        createdAt: DateTime.tryParse(
                (json['created_at'] ?? json['createdAt']) as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
      };
}

class JobApplication {
  final String id;
  final String companyInitials;
  final Color logoBackground;
  final Color logoTextColor;
  final String jobTitle;
  final String companyName;
  final String dateApplied;
  final String resumeVersion;
  final int atsScore;
  final String stage;
  final double opacity;
  final String? resumeId;
  final String? optimizedResumeId;
  final String? location;
  final bool archived;
  final DateTime? interviewAt;
  final String interviewType;
  final List<TimelineEvent> timeline;
  final String jobDescription;
  final String jobUrl;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;

  const JobApplication({
    this.id = '',
    required this.companyInitials,
    required this.logoBackground,
    required this.logoTextColor,
    required this.jobTitle,
    required this.companyName,
    required this.dateApplied,
    required this.resumeVersion,
    required this.atsScore,
    required this.stage,
    this.opacity = 1.0,
    this.resumeId,
    this.optimizedResumeId,
    this.location,
    this.archived = false,
    this.interviewAt,
    this.interviewType = '',
    this.timeline = const [],
    this.jobDescription = '',
    this.jobUrl = '',
    this.matchedKeywords = const [],
    this.missingKeywords = const [],
  });

  JobApplication copyWith({
    String? id,
    bool? archived,
    String? stage,
    int? atsScore,
    DateTime? interviewAt,
    String? interviewType,
    List<TimelineEvent>? timeline,
  }) =>
      JobApplication(
        id: id ?? this.id,
        companyInitials: companyInitials,
        logoBackground: logoBackground,
        logoTextColor: logoTextColor,
        jobTitle: jobTitle,
        companyName: companyName,
        dateApplied: dateApplied,
        resumeVersion: resumeVersion,
        atsScore: atsScore ?? this.atsScore,
        stage: stage ?? this.stage,
        opacity: opacity,
        resumeId: resumeId,
        optimizedResumeId: optimizedResumeId,
        location: location,
        archived: archived ?? this.archived,
        interviewAt: interviewAt ?? this.interviewAt,
        interviewType: interviewType ?? this.interviewType,
        timeline: timeline ?? this.timeline,
        jobDescription: jobDescription,
        jobUrl: jobUrl,
        matchedKeywords: matchedKeywords,
        missingKeywords: missingKeywords,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyInitials': companyInitials,
        'logoBackground': logoBackground.value,
        'logoTextColor': logoTextColor.value,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'dateApplied': dateApplied,
        'resumeVersion': resumeVersion,
        'atsScore': atsScore,
        'stage': stage,
        'opacity': opacity,
        'resumeId': resumeId,
        'optimizedResumeId': optimizedResumeId,
        'location': location,
        'archived': archived,
        'interviewAt': interviewAt?.toIso8601String(),
        'interviewType': interviewType,
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'jobDescription': jobDescription,
        'jobUrl': jobUrl,
        'matchedKeywords': matchedKeywords,
        'missingKeywords': missingKeywords,
      };

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    final timelineJson = json['timeline'] as List<dynamic>? ?? [];
    final matchedJson = json['matchedKeywords'] as List<dynamic>? ?? [];
    final missingJson = json['missingKeywords'] as List<dynamic>? ?? [];

    DateTime? interviewAt;
    final interviewAtStr = json['interviewAt'] as String?;
    if (interviewAtStr != null && interviewAtStr.isNotEmpty) {
      interviewAt = DateTime.tryParse(interviewAtStr);
    }

    return JobApplication(
      id: json['id'] as String? ?? '',
      companyInitials: json['companyInitials'] as String? ?? '',
      logoBackground:
          Color(json['logoBackground'] as int? ?? 0xFFFFFFFF),
      logoTextColor:
          Color(json['logoTextColor'] as int? ?? 0xFF000000),
      jobTitle: json['jobTitle'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      dateApplied: json['dateApplied'] as String? ?? '',
      resumeVersion: json['resumeVersion'] as String? ?? '',
      atsScore: (json['atsScore'] as num?)?.toInt() ?? 0,
      stage: json['stage'] as String? ?? 'applied',
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      resumeId: json['resumeId'] as String?,
      optimizedResumeId: json['optimizedResumeId'] as String?,
      location: json['location'] as String?,
      archived: json['archived'] as bool? ?? false,
      interviewAt: interviewAt,
      interviewType: json['interviewType'] as String? ?? '',
      timeline: timelineJson
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      jobDescription: json['jobDescription'] as String? ?? '',
      jobUrl: json['jobUrl'] as String? ?? '',
      matchedKeywords: matchedJson.map((e) => e as String).toList(),
      missingKeywords: missingJson.map((e) => e as String).toList(),
    );
  }

  /// Parse a JobApplication from the backend API response format.
  factory JobApplication.fromApiJson(Map<String, dynamic> json) {
    final jobId =
        (json['id'] ?? json['job_id'] ?? json['jobId'])?.toString() ?? '';
    final timelineJson = json['timeline'] as List<dynamic>? ?? [];
    final matchedJson = (json['matched_keywords'] ?? json['matchedKeywords']) as List<dynamic>? ?? [];
    final missingJson = (json['missing_keywords'] ?? json['missingKeywords']) as List<dynamic>? ?? [];

    DateTime? interviewAt;
    final interviewAtStr = (json['interview_at'] ?? json['interviewAt']) as String?;
    if (interviewAtStr != null && interviewAtStr.isNotEmpty) {
      interviewAt = DateTime.tryParse(interviewAtStr);
    }

    // Generate local display fields from backend data
    final companyName = (json['company_name'] ?? json['companyName']) as String? ?? '';
    final initials = companyName.length >= 2
        ? companyName.substring(0, 2).toUpperCase()
        : companyName.toUpperCase();
    final palette = _logoPalette[companyName.hashCode.abs() % _logoPalette.length];

    DateTime? createdAt;
    final createdAtStr = (json['created_at'] ?? json['createdAt']) as String?;
    if (createdAtStr != null) createdAt = DateTime.tryParse(createdAtStr);

    String dateApplied = '';
    if (createdAt != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dateApplied = '${months[createdAt.month - 1]} ${createdAt.day}';
    }

    return JobApplication(
      id: jobId,
      companyInitials: initials,
      logoBackground: palette[0],
      logoTextColor: palette[1],
      jobTitle: (json['job_title'] ?? json['jobTitle']) as String? ?? '',
      companyName: companyName,
      dateApplied: dateApplied,
      resumeVersion: '',
      atsScore: ((json['ats_score'] ?? json['atsScore']) as num?)?.toInt() ?? 0,
      stage: _normalizeStage(json['stage'] as String? ?? 'Applied'),
      opacity: 1.0,
      resumeId: (json['resume_id'] ?? json['resumeId']) as String?,
      optimizedResumeId: (json['optimized_resume_id'] ?? json['optimizedResumeId']) as String?,
      location: json['location'] as String?,
      archived: (json['is_archived'] ?? json['archived']) as bool? ?? false,
      interviewAt: interviewAt,
      interviewType: (json['interview_type'] ?? json['interviewType']) as String? ?? '',
      timeline: timelineJson
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      jobDescription: json['jobDescription'] as String? ?? '',
      jobUrl: json['jobUrl'] as String? ?? '',
      matchedKeywords: matchedJson.map((e) => e as String).toList(),
      missingKeywords: missingJson.map((e) => e as String).toList(),
    );
  }
}

/// Maps backend stage strings (any case) to the capitalized form used in the UI.
String _normalizeStage(String raw) {
  switch (raw.toLowerCase()) {
    case 'wishlist':  return 'Wishlist';
    case 'applied':   return 'Applied';
    case 'interview': return 'Interview';
    case 'offer':     return 'Offer';
    case 'accepted':  return 'Accepted';
    case 'rejected':  return 'Rejected';
    default:
      // Unknown value: capitalize first letter and return as-is
      if (raw.isEmpty) return 'Applied';
      return raw[0].toUpperCase() + raw.substring(1);
  }
}

const List<List<Color>> _logoPalette = [
  [Color(0xFFE6F1FB), Color(0xFF185FA5)],
  [Color(0xFFFBEAF0), Color(0xFF993556)],
  [Color(0xFFEAF3DE), Color(0xFF3B6D11)],
  [Color(0xFFFAEEDA), Color(0xFF854F0B)],
  [Color(0xFFEDE9FA), Color(0xFF5B3EBB)],
  [Color(0xFFE8F7F2), Color(0xFF1D6B50)],
];
