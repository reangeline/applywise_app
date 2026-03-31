// Models used exclusively in the pre-auth onboarding ATS-analysis flow.

class ExperienceEntry {
  String role;
  String company;
  String period;
  String description;

  ExperienceEntry({
    this.role = '',
    this.company = '',
    this.period = '',
    this.description = '',
  });
}

class EducationEntry {
  String degree;
  String institution;
  String period;

  EducationEntry({
    this.degree = '',
    this.institution = '',
    this.period = '',
  });
}

class ManualResumeForm {
  String name;
  String targetRole;
  String city;
  String summary;
  List<ExperienceEntry> experiences;
  List<EducationEntry> education;
  List<String> skills;

  ManualResumeForm({
    this.name = '',
    this.targetRole = '',
    this.city = '',
    this.summary = '',
    List<ExperienceEntry>? experiences,
    List<EducationEntry>? education,
    List<String>? skills,
  })  : experiences = experiences ?? [],
        education = education ?? [],
        skills = skills ?? [];
}

/// Builds a structured plain-text representation of the resume for ATS analysis.
String buildResumeText(ManualResumeForm form) {
  return """
NOME: ${form.name}
CARGO DESEJADO: ${form.targetRole}${form.city.isNotEmpty ? '\nLOCALIZAÇÃO: ${form.city}' : ''}

RESUMO PROFISSIONAL:
${form.summary}

EXPERIÊNCIA:
${form.experiences.map((e) => '''
${e.role} | ${e.company} | ${e.period}
${e.description}
''').join('\n')}

EDUCAÇÃO:
${form.education.map((e) => '${e.degree} | ${e.institution} | ${e.period}').join('\n')}

HABILIDADES:
${form.skills.join(', ')}
  """;
}

/// Holds the ATS analysis result computed before the user has an account.
class OnboardingAtsResult {
  final int score;
  final int totalIssues;
  final List<String> problemCategories;
  final Map<String, dynamic> rawData;

  const OnboardingAtsResult({
    required this.score,
    required this.totalIssues,
    required this.problemCategories,
    required this.rawData,
  });
}
