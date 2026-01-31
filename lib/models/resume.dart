class Resume {
  final String id;
  final String optimizedText;
  final List<String> suggestions;
  final double score;
  final DateTime createdAt;

  Resume({
    required this.id,
    required this.optimizedText,
    required this.suggestions,
    required this.score,
    required this.createdAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] ?? '',
      optimizedText: json['optimized_text'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      score: (json['score'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'optimized_text': optimizedText,
      'suggestions': suggestions,
      'score': score,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Resume copyWith({
    String? id,
    String? optimizedText,
    List<String>? suggestions,
    double? score,
    DateTime? createdAt,
  }) {
    return Resume(
      id: id ?? this.id,
      optimizedText: optimizedText ?? this.optimizedText,
      suggestions: suggestions ?? this.suggestions,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
