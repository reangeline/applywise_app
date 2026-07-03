class PipelineAnalytics {
  final int totalApplications;
  final double responseRate;
  final double averageAtsScore;
  final int interviewCount;
  final int offerCount;
  final int ghostedCount;
  final int applicationsThisWeek;
  final List<ScoreRangeBucket> scoreRangeBuckets;
  final BestResume? bestResumeVersion;
  final List<StageCount> stageDistribution;
  final List<WeeklyPoint> weeklyActivity;
  final String coachInsight;

  const PipelineAnalytics({
    required this.totalApplications,
    required this.responseRate,
    required this.averageAtsScore,
    required this.interviewCount,
    required this.offerCount,
    required this.ghostedCount,
    required this.applicationsThisWeek,
    required this.scoreRangeBuckets,
    this.bestResumeVersion,
    required this.stageDistribution,
    required this.weeklyActivity,
    required this.coachInsight,
  });

  factory PipelineAnalytics.fromJson(Map<String, dynamic> json) =>
      PipelineAnalytics(
        totalApplications: ((json['totalApplications'] ?? json['total_applications']) as num?)?.toInt() ?? 0,
        responseRate: ((json['responseRate'] ?? json['response_rate']) as num?)?.toDouble() ?? 0.0,
        averageAtsScore: ((json['averageAtsScore'] ?? json['average_ats_score']) as num?)?.toDouble() ?? 0.0,
        interviewCount: ((json['interviewCount'] ?? json['interview_count']) as num?)?.toInt() ?? 0,
        offerCount: ((json['offerCount'] ?? json['offer_count']) as num?)?.toInt() ?? 0,
        ghostedCount: ((json['ghostedCount'] ?? json['ghosted_count']) as num?)?.toInt() ?? 0,
        applicationsThisWeek: ((json['applicationsThisWeek'] ?? json['applications_this_week']) as num?)?.toInt() ?? 0,
        scoreRangeBuckets: ((json['scoreRangeBuckets'] ?? json['score_range_buckets']) as List<dynamic>? ?? [])
            .map((e) => ScoreRangeBucket.fromJson(e as Map<String, dynamic>))
            .toList(),
        bestResumeVersion: (json['bestResumeVersion'] ?? json['best_resume_version']) != null
            ? BestResume.fromJson(
                (json['bestResumeVersion'] ?? json['best_resume_version']) as Map<String, dynamic>)
            : null,
        stageDistribution:
            ((json['stageDistribution'] ?? json['stage_distribution']) as List<dynamic>? ?? [])
                .map((e) => StageCount.fromJson(e as Map<String, dynamic>))
                .toList(),
        weeklyActivity: ((json['weeklyActivity'] ?? json['weekly_activity']) as List<dynamic>? ?? [])
            .map((e) => WeeklyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        coachInsight: (json['coachInsight'] ?? json['coach_insight']) as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'total_applications': totalApplications,
        'response_rate': responseRate,
        'average_ats_score': averageAtsScore,
        'interview_count': interviewCount,
        'offer_count': offerCount,
        'ghosted_count': ghostedCount,
        'applications_this_week': applicationsThisWeek,
        'score_range_buckets':
            scoreRangeBuckets.map((e) => e.toJson()).toList(),
        'best_resume_version': bestResumeVersion?.toJson(),
        'stage_distribution':
            stageDistribution.map((e) => e.toJson()).toList(),
        'weekly_activity': weeklyActivity.map((e) => e.toJson()).toList(),
        'coach_insight': coachInsight,
      };
}

class ScoreRangeBucket {
  final String label;
  final double responseRate;
  final int count;

  const ScoreRangeBucket({
    required this.label,
    required this.responseRate,
    required this.count,
  });

  factory ScoreRangeBucket.fromJson(Map<String, dynamic> json) =>
      ScoreRangeBucket(
        label: json['label'] as String? ?? '',
        responseRate: ((json['responseRate'] ?? json['response_rate']) as num?)?.toDouble() ?? 0.0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'response_rate': responseRate,
        'count': count,
      };
}

class BestResume {
  final String resumeId;
  final String resumeName;
  final double responseRate;
  final int applicationCount;

  const BestResume({
    required this.resumeId,
    required this.resumeName,
    required this.responseRate,
    required this.applicationCount,
  });

  factory BestResume.fromJson(Map<String, dynamic> json) => BestResume(
        resumeId: (json['resumeId'] ?? json['resume_id']) as String? ?? '',
        resumeName: (json['resumeName'] ?? json['resume_name']) as String? ?? '',
        responseRate: ((json['responseRate'] ?? json['response_rate']) as num?)?.toDouble() ?? 0.0,
        applicationCount: ((json['applicationCount'] ?? json['application_count']) as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'resume_id': resumeId,
        'resume_name': resumeName,
        'response_rate': responseRate,
        'application_count': applicationCount,
      };
}

class StageCount {
  final String stage;
  final int count;

  const StageCount({
    required this.stage,
    required this.count,
  });

  factory StageCount.fromJson(Map<String, dynamic> json) => StageCount(
        stage: json['stage'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'stage': stage,
        'count': count,
      };
}

class WeeklyPoint {
  final String weekLabel;
  final int applicationCount;
  final int responseCount;

  const WeeklyPoint({
    required this.weekLabel,
    required this.applicationCount,
    required this.responseCount,
  });

  factory WeeklyPoint.fromJson(Map<String, dynamic> json) => WeeklyPoint(
        weekLabel: (json['weekLabel'] ?? json['week_label']) as String? ?? '',
        applicationCount: ((json['applicationCount'] ?? json['application_count']) as num?)?.toInt() ?? 0,
        responseCount: ((json['responseCount'] ?? json['response_count']) as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'week_label': weekLabel,
        'application_count': applicationCount,
        'response_count': responseCount,
      };
}
