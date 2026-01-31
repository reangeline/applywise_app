import '../config/constants.dart';
import '../models/resume.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ResumeService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<Resume?> optimizeResume({
    required String resumeText,
    required String jobDescription,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return null;

      final response = await _apiService.post(
        AppConstants.optimizeResumeEndpoint,
        {
          'resume_text': resumeText,
          'job_description': jobDescription,
        },
        token: token,
      );

      return Resume.fromJson(response);
    } catch (e) {
      throw Exception('Failed to optimize resume: $e');
    }
  }

  Future<List<Resume>> getResumes() async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return [];

      final response = await _apiService.get(
        AppConstants.resumesEndpoint,
        token: token,
      );

      final List<dynamic> resumesList = response as List<dynamic>? ?? [];
      return resumesList.map((json) => Resume.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
