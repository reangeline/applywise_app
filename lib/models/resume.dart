class WorkExperience {
  final String role;
  final String company;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String description;

  WorkExperience({
    required this.role,
    required this.company,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    required this.description,
  });

  static String _coerceString(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.map((e) => e.toString()).join('\n');
    return value.toString();
  }

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      role: _coerceString(json['role']),
      company: _coerceString(json['company']),
      startDate: _coerceString(json['start_date']),
      endDate: json['end_date'] != null ? _coerceString(json['end_date']) : null,
      isCurrent: json['is_current'] ?? false,
      description: _coerceString(json['description']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'company': company,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'description': description,
    };
  }
}

class Education {
  final String institution;
  final String degree;
  final String startDate;
  final String? endDate;
  final bool isCurrent;

  Education({
    required this.institution,
    required this.degree,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
  });

  static String _coerceString(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.map((e) => e.toString()).join('\n');
    return value.toString();
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: _coerceString(json['institution']),
      degree: _coerceString(json['degree']),
      startDate: _coerceString(json['start_date']),
      endDate: json['end_date'] != null ? _coerceString(json['end_date']) : null,
      isCurrent: json['is_current'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
    };
  }
}

class Project {
  final String name;
  final String? url;
  final String description;

  Project({
    required this.name,
    this.url,
    required this.description,
  });

  static String _coerceString(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.map((e) => e.toString()).join('\n');
    return value.toString();
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: _coerceString(json['name']),
      url: json['url']?.toString(),
      description: _coerceString(json['description']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'description': description,
    };
  }
}

class Language {
  final String language;
  final String proficiency;

  Language({
    required this.language,
    required this.proficiency,
  });

  static String _coerceString(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.map((e) => e.toString()).join(', ');
    return value.toString();
  }

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      language: _coerceString(json['language']),
      proficiency: _coerceString(json['proficiency']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'proficiency': proficiency,
    };
  }
}

class LinkedInExperience {
  final String role;
  final String company;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String description;

  const LinkedInExperience({
    required this.role,
    required this.company,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    required this.description,
  });

  factory LinkedInExperience.fromJson(Map<String, dynamic> json) {
    // description may be a List<String> or a plain String; also handles PascalCase
    final rawDesc = json['description'] ?? json['Description'];
    final String desc;
    if (rawDesc is List) {
      desc = rawDesc.map((e) => e.toString()).join('\n');
    } else {
      desc = rawDesc?.toString() ?? '';
    }
    return LinkedInExperience(
      role: json['role']?.toString() ?? json['Role']?.toString() ??
            json['title']?.toString() ?? json['Title']?.toString() ??
            json['position']?.toString() ?? '',
      company: json['company']?.toString() ?? json['Company']?.toString() ??
               json['company_name']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? json['StartDate']?.toString() ??
                 json['startDate']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? json['EndDate']?.toString() ??
               json['endDate']?.toString(),
      isCurrent: json['is_current'] == true || json['IsCurrent'] == true ||
                 json['isCurrent'] == true,
      description: desc,
    );
  }
}

class LinkedInLanguage {
  final String name;
  final String level;

  const LinkedInLanguage({required this.name, required this.level});

  factory LinkedInLanguage.fromJson(Map<String, dynamic> json) {
    return LinkedInLanguage(
      name: json['name']?.toString() ?? json['Name']?.toString() ??
            json['language']?.toString() ?? '',
      level: json['level']?.toString() ?? json['Level']?.toString() ??
             json['proficiency']?.toString() ?? json['Proficiency']?.toString() ??
             json['fluency']?.toString() ?? '',
    );
  }
}

class LinkedInOptimizedData {
  final String resumeId;
  final String headline;
  final String about;
  final List<LinkedInExperience> experiences;
  final List<String> skills;
  final List<LinkedInLanguage> languages;
  final double? profileStrengthScore;
  final List<String> suggestions;

  const LinkedInOptimizedData({
    required this.resumeId,
    required this.headline,
    required this.about,
    required this.experiences,
    required this.skills,
    required this.languages,
    this.profileStrengthScore,
    required this.suggestions,
  });

  factory LinkedInOptimizedData.fromJson(Map<String, dynamic> json) {
    // Support both snake_case (API) and PascalCase (DynamoDB raw) keys
    final parsedData = (json['parsed_data'] ?? json['ParsedData']) as Map<String, dynamic>? ?? json;


    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      if (raw is List) return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }

    List<String> toStringList(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return LinkedInOptimizedData(
      resumeId: json['resume_id']?.toString() ??
          json['source_resume_id']?.toString() ??
          json['ResumeID']?.toString() ??
          json['SourceResumeID']?.toString() ??
          json['ID']?.toString() ?? '',
      headline: parsedData['headline']?.toString() ?? '',
      about: parsedData['about']?.toString() ?? '',
      experiences: parseList(
        parsedData['experiences'] ?? parsedData['experience'] ??
        parsedData['work_experience'] ?? parsedData['work_experiences'],
        LinkedInExperience.fromJson,
      ),
      skills: toStringList(parsedData['skills'] ?? parsedData['skill']),
      languages: parseList(
        parsedData['languages'] ?? parsedData['language'],
        LinkedInLanguage.fromJson,
      ),
      profileStrengthScore: toDouble(
        parsedData['profile_strength_score'] ?? parsedData['ProfileStrengthScore'],
      ),
      suggestions: toStringList(
        json['suggestions'] ?? json['Suggestions'],
      ),
    );
  }
}

class SalaryEstimate {
  final bool found;
  final String? currency;
  final double? minSalary;
  final double? maxSalary;
  final double? midpoint;
  final String? period;
  final String? location;
  final String? seniority;
  final String? notes;
  final String? disclaimer;

  const SalaryEstimate({
    required this.found,
    this.currency,
    this.minSalary,
    this.maxSalary,
    this.midpoint,
    this.period,
    this.location,
    this.seniority,
    this.notes,
    this.disclaimer,
  });

  factory SalaryEstimate.fromJson(Map<String, dynamic> json) {
    final found = json['found'] == true;
    if (!found) return const SalaryEstimate(found: false);

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return SalaryEstimate(
      found: true,
      currency: json['currency']?.toString(),
      minSalary: toDouble(json['min_salary']),
      maxSalary: toDouble(json['max_salary']),
      midpoint: toDouble(json['midpoint']),
      period: json['period']?.toString(),
      location: json['location']?.toString(),
      seniority: json['seniority']?.toString(),
      notes: json['notes']?.toString(),
      disclaimer: json['disclaimer']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    if (!found) return {'found': false};
    return {
      'found': true,
      'currency': currency,
      'min_salary': minSalary,
      'max_salary': maxSalary,
      'midpoint': midpoint,
      'period': period,
      'location': location,
      'seniority': seniority,
      'notes': notes,
      'disclaimer': disclaimer,
    };
  }
}

class PersonalInfo {
  final String fullName;
  final String email;
  final String? phone;
  final String? currentRole;
  final String? country;
  final String? state;
  final String? city;
  final String? linkedinUrl;
  final String? websiteUrl;
  final String? githubUrl;
  final String? summary;

  PersonalInfo({
    required this.fullName,
    required this.email,
    this.phone,
    this.currentRole,
    this.country,
    this.state,
    this.city,
    this.linkedinUrl,
    this.websiteUrl,
    this.githubUrl,
    this.summary,
  });

  static String? _toStr(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).join('\n');
    return v.toString();
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      fullName: _toStr(json['full_name']) ?? '',
      email: _toStr(json['email']) ?? '',
      phone: _toStr(json['phone']),
      currentRole: _toStr(json['current_role']),
      country: _toStr(json['country']),
      state: _toStr(json['state']),
      city: _toStr(json['city']),
      linkedinUrl: _toStr(json['linkedin_url']),
      websiteUrl: _toStr(json['website_url']),
      githubUrl: _toStr(json['github_url']),
      summary: _toStr(json['summary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'current_role': currentRole,
      'country': country,
      'state': state,
      'city': city,
      'linkedin_url': linkedinUrl,
      'website_url': websiteUrl,
      'github_url': githubUrl,
      'summary': summary,
    };
  }
}

class Resume {
  final String id;
  final String type; // 'manual' ou 'optimized'
  final String? nickname;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Para currículos manuais
  final PersonalInfo? personal;
  final List<WorkExperience>? experiences;
  final List<Education>? education;
  final List<Project>? projects;
  final List<Language>? languages;

  // Para currículos otimizados (legacy)
  final String? optimizedText;
  final List<String>? suggestions;
  final List<String>? missingRequirements;
  final double? score;

  // Dados da vaga (otimizados)
  final String? targetCompany;
  final String? targetRole;
  final SalaryEstimate? salaryEstimate;

  // Para currículos LinkedIn
  final LinkedInOptimizedData? linkedInData;

  // ATS data from PDF parse
  final int? atsScore;
  final List<String>? atsImprovements;

  Resume({
    required this.id,
    required this.type,
    this.nickname,
    required this.createdAt,
    this.updatedAt,
    this.personal,
    this.experiences,
    this.education,
    this.projects,
    this.languages,
    this.optimizedText,
    this.suggestions,
    this.missingRequirements,
    this.score,
    this.targetCompany,
    this.targetRole,
    this.salaryEstimate,
    this.linkedInData,
    this.atsScore,
    this.atsImprovements,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    
    final rawType = json['type'] ?? json['Type'];
    final normalizedType = rawType?.toString().toLowerCase();

    // Detectar tipo dentro do parsed_data (LinkedIn não tem 'type' na raiz)
    final rawParsedData = json['parsed_data'] ?? json['ParsedData'];
    final parsedDataType = rawParsedData is Map
        ? (rawParsedData as Map<String, dynamic>)['type']?.toString().toLowerCase()
        : null;

    // Se o JSON tem um tipo explícito e válido, usar ele
    final explicitType = normalizedType == 'manual'
        ? 'manual'
        : (normalizedType == 'linkedin' || parsedDataType == 'linkedin'
            ? 'linkedin'
            : (normalizedType != null && normalizedType.contains('optim')
                ? 'optimized'
                : null));

    // Só inferir o tipo se não houver um tipo explícito
    final hasOptimizedPayload = json['optimized_text'] != null ||
        json['optimized_content'] != null ||
        json['OptimizedContent'] != null ||
        json['match_score'] != null ||
        json['MatchScore'] != null ||
        json['score'] != null ||
        (json['suggestions'] is List &&
            (json['suggestions'] as List).isNotEmpty) ||
        (json['Suggestions'] is List &&
            (json['Suggestions'] as List).isNotEmpty);

    // Priorizar o tipo explícito do JSON, só inferir se não houver
    final type = explicitType ?? (hasOptimizedPayload ? 'optimized' : 'manual');


    // Para currículos manuais, os dados estão em parsed_data
    final parsedData = json['parsed_data'] ?? json['ParsedData'];


    // Para QUALQUER tipo, se tiver parsed_data, usar ele
    final finalData = parsedData != null 
        ? parsedData as Map<String, dynamic> 
        : json;

    List<String>? toStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      // Se vier como string única, encapsula em lista
      return [value.toString()];
    }

    // Extrair targetRole a partir do parsed_data
    String? extractTargetRole() {
      if (finalData['target_role'] != null) return finalData['target_role'].toString();
      if (finalData['job_title'] != null) return finalData['job_title'].toString();
      if (type == 'optimized') {
        final personal = finalData['personal'];
        if (personal is Map) {
          return (personal as Map<String, dynamic>)['current_role']?.toString();
        }
      }
      return null;
    }

    return Resume(
      id: json['id'] ?? json['ID'] ?? '',
      type: type,
      nickname: finalData['nickname'] ?? json['nickname'] ?? json['Nickname'],
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['UpdatedAt'] != null
              ? DateTime.parse(json['UpdatedAt'])
              : null,
      // Campos para currículos com dados estruturados (manual OU otimizado)
      personal: finalData['personal'] != null
          ? PersonalInfo.fromJson(finalData['personal'])
          : null,
      experiences: finalData['experiences'] != null
          ? (finalData['experiences'] as List)
              .map((e) => WorkExperience.fromJson(e))
              .toList()
          : null,
      education: finalData['education'] != null
          ? (finalData['education'] as List)
              .map((e) => Education.fromJson(e))
              .toList()
          : null,
      projects: finalData['projects'] != null
          ? (finalData['projects'] as List).map((e) => Project.fromJson(e)).toList()
          : null,
      languages: finalData['languages'] != null
          ? (finalData['languages'] as List).map((e) => Language.fromJson(e)).toList()
          : null,
      // Campos para currículos otimizados
      optimizedText: type == 'optimized'
          ? (json['optimized_text'] ??
              json['optimized_content'] ??
              json['OptimizedContent'] ??
              '')
          : null,
      suggestions: type == 'optimized'
            ? toStringList(json['suggestions'] ?? json['Suggestions'])
          : null,
          missingRequirements: type == 'optimized'
            ? toStringList(json['missing_requirements'] ?? json['MissingRequirements'])
            : null,
      score: type == 'optimized'
          ? (json['score'] ?? json['match_score'] ?? json['MatchScore'] ?? 0)
              .toDouble()
          : null,
      targetCompany: finalData['target_company']?.toString() ??
          finalData['company']?.toString(),
      targetRole: extractTargetRole(),
      salaryEstimate: json['salary_estimate'] != null
          ? SalaryEstimate.fromJson(json['salary_estimate'] as Map<String, dynamic>)
          : null,
      linkedInData: parsedDataType == 'linkedin'
          ? LinkedInOptimizedData.fromJson(json)
          : null,
      atsScore: finalData['ats_score'] is num
          ? (finalData['ats_score'] as num).round()
          : null,
      atsImprovements: toStringList(finalData['ats_improvements']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'type': type,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };

    if (type == 'manual') {
      if (personal != null) data['personal'] = personal!.toJson();
      if (experiences != null) {
        data['experiences'] = experiences!.map((e) => e.toJson()).toList();
      }
      if (education != null) {
        data['education'] = education!.map((e) => e.toJson()).toList();
      }
      if (projects != null) {
        data['projects'] = projects!.map((e) => e.toJson()).toList();
      }
    } else {
      if (optimizedText != null) data['optimized_text'] = optimizedText;
      if (suggestions != null) data['suggestions'] = suggestions;
      if (missingRequirements != null) data['missing_requirements'] = missingRequirements;
      if (score != null) data['score'] = score;
      if (salaryEstimate != null) data['salary_estimate'] = salaryEstimate!.toJson();
    }

    return data;
  }

  Resume copyWith({
    String? id,
    String? type,
    String? nickname,
    DateTime? createdAt,
    DateTime? updatedAt,
    PersonalInfo? personal,
    List<WorkExperience>? experiences,
    List<Education>? education,
    List<Project>? projects,
    String? optimizedText,
    List<String>? suggestions,
    List<String>? missingRequirements,
    double? score,
    String? targetCompany,
    String? targetRole,
    SalaryEstimate? salaryEstimate,
    LinkedInOptimizedData? linkedInData,
    int? atsScore,
    List<String>? atsImprovements,
  }) {
    return Resume(
      id: id ?? this.id,
      type: type ?? this.type,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      personal: personal ?? this.personal,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      projects: projects ?? this.projects,
      optimizedText: optimizedText ?? this.optimizedText,
      suggestions: suggestions ?? this.suggestions,
      missingRequirements: missingRequirements ?? this.missingRequirements,
      score: score ?? this.score,
      targetCompany: targetCompany ?? this.targetCompany,
      targetRole: targetRole ?? this.targetRole,
      salaryEstimate: salaryEstimate ?? this.salaryEstimate,
      linkedInData: linkedInData ?? this.linkedInData,
      atsScore: atsScore ?? this.atsScore,
      atsImprovements: atsImprovements ?? this.atsImprovements,
    );
  }
}
