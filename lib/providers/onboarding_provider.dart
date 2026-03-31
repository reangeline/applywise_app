import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/onboarding_models.dart';

/// Holds all pre-authentication onboarding state: the resume data the user
/// submitted (PDF bytes or manual text) and the ATS result from the backend.
///
/// This provider survives until the user completes sign-up, at which point
/// [associateWithAuth] re-sends the data to the backend linked to the new
/// account and [clear] is called.
class OnboardingProvider with ChangeNotifier {
  // ─── Resume input ────────────────────────────────────────────────────────────

  Uint8List? pdfBytes;
  String? pdfFileName;
  String? resumeText;

  /// 'pdf' | 'manual'
  String? entryMode;

  // ─── ATS result ──────────────────────────────────────────────────────────────

  OnboardingAtsResult? atsResult;

  // ─── Parsed resume data (from parse-pdf response) ────────────────────────────

  /// Structured data returned by POST /api/v1/resumes/parse-pdf.
  /// Contains personal, experiences, education, projects, languages.
  /// Used to populate "parsed_resume" on email signup or to call
  /// POST /api/v1/resumes/manual after social signup.
  Map<String, dynamic>? parsedResumeData;

  // ─── Setters ─────────────────────────────────────────────────────────────────

  void setPdfData(Uint8List bytes, String fileName) {
    pdfBytes = bytes;
    pdfFileName = fileName;
    entryMode = 'pdf';
    resumeText = null;
    notifyListeners();
  }

  void setResumeText(String text) {
    resumeText = text;
    entryMode = 'manual';
    pdfBytes = null;
    pdfFileName = null;
    notifyListeners();
  }

  void setAtsResult(OnboardingAtsResult result) {
    atsResult = result;
    notifyListeners();
  }

  void setParsedResumeData(Map<String, dynamic> data) {
    parsedResumeData = data;
    notifyListeners();
  }

  void clear() {
    pdfBytes = null;
    pdfFileName = null;
    resumeText = null;
    entryMode = null;
    atsResult = null;
    parsedResumeData = null;
    notifyListeners();
  }
}
