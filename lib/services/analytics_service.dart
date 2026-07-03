import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized Firebase Analytics service.
///
/// Design principles:
///  - One call per meaningful business action (not every tap).
///  - Parameters are kept short (Firebase max 100 chars per value).
///  - User ID + subscription_tier property are set after every auth event so
///    every subsequent event is automatically segmented by user and tier.
///
/// Key dashboards this feeds:
///  Acquisition  → onboarding funnel (step_viewed / completed / skipped)
///  Activation   → first resume_optimize_success
///  Retention    → repeated logins, PDF downloads
///  Revenue      → paywall_viewed → upgrade_tapped → subscription_purchased
///  Engagement   → screen views, tab changes
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Navigator observer — pass this to [MaterialApp.navigatorObservers].
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Identity ────────────────────────────────────────────────────────────────

  /// Attach the user ID so all future events are linked to this person.
  /// Call after login / signup. Pass null on logout.
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set a persistent user property.
  /// [name] must match the property registered in the Firebase console.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // ── Screen views ─────────────────────────────────────────────────────────────

  /// Log a manual screen view (use when automatic route detection is not enough).
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ── Onboarding funnel ────────────────────────────────────────────────────────
  // Answers: "Where do users drop from onboarding?"

  /// Each page of the onboarding carousel that is displayed.
  Future<void> logOnboardingStepViewed({
    required int stepIndex,
    required String stepTitle,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_step_viewed',
      parameters: {
        'step_index': stepIndex,
        'step_title': stepTitle.substring(0, stepTitle.length.clamp(0, 100)),
      },
    );
  }

  /// User pressed "Get Started" at the last onboarding page.
  Future<void> logOnboardingCompleted() async {
    await _analytics.logEvent(name: 'onboarding_completed');
  }

  /// User tapped "Skip" before completing onboarding.
  Future<void> logOnboardingSkipped({required int atStep}) async {
    await _analytics.logEvent(
      name: 'onboarding_skipped',
      parameters: {'at_step': atStep},
    );
  }

  // ── Auth events ──────────────────────────────────────────────────────────────
  // Answers: "How many users are logging in? How many forget their password?"

  /// Successful login. Also set userId + subscription_tier immediately after.
  Future<void> logLogin({String method = 'email'}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Successful sign-up. Also set userId + subscription_tier immediately after.
  Future<void> logSignUp({String method = 'email'}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// User submitted the "Forgot password" form.
  Future<void> logPasswordResetRequested() async {
    await _analytics.logEvent(name: 'password_reset_requested');
  }

  /// User confirmed logout.
  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    await _analytics.setUserId(id: null);
    await _analytics.setUserProperty(name: 'subscription_tier', value: null);
  }

  // ── Resume events ────────────────────────────────────────────────────────────
  // Answers: "What features drive engagement? What is the ATS score distribution?"

  /// User created a new resume manually.
  Future<void> logResumeCreated({String type = 'manual'}) async {
    await _analytics.logEvent(
      name: 'resume_created',
      parameters: {'resume_type': type},
    );
  }

  /// User opened the detail / bottom-sheet of a resume.
  Future<void> logResumeDetailViewed({
    required String resumeType,
    double? score,
  }) async {
    await _analytics.logEvent(
      name: 'resume_detail_viewed',
      parameters: {
        'resume_type': resumeType,
        if (score != null) 'ats_score': score.toInt(),
      },
    );
  }

  /// User downloaded a PDF export.
  Future<void> logResumePdfDownloaded({required String resumeType}) async {
    await _analytics.logEvent(
      name: 'resume_pdf_downloaded',
      parameters: {'resume_type': resumeType},
    );
  }

  /// User deleted a resume (confirmed via dialog).
  Future<void> logResumeDeleted({required String resumeType}) async {
    await _analytics.logEvent(
      name: 'resume_deleted',
      parameters: {'resume_type': resumeType},
    );
  }

  /// User submitted a resume for AI optimization.
  Future<void> logResumeOptimizeStarted({
    String? targetCompany,
    String? targetRole,
  }) async {
    await _analytics.logEvent(
      name: 'resume_optimize_started',
      parameters: {
        if (targetCompany != null) 'target_company': targetCompany,
        if (targetRole != null) 'target_role': targetRole,
      },
    );
  }

  /// AI optimization returned results successfully.
  /// [score] is the ATS match percentage (0-100). Sending it here
  /// allows Firebase to compute score distributions and averages.
  Future<void> logResumeOptimizeSuccess({
    String? targetCompany,
    String? targetRole,
  }) async {
    await _analytics.logEvent(
      name: 'resume_optimize_success',
      parameters: {
        if (targetCompany != null) 'target_company': targetCompany,
        if (targetRole != null) 'target_role': targetRole,
      },
    );
  }

  /// AI optimization failed.
  Future<void> logResumeOptimizeError(String errorMessage) async {
    await _analytics.logEvent(
      name: 'resume_optimize_error',
      parameters: {
        'error': errorMessage.substring(0, errorMessage.length.clamp(0, 100)),
      },
    );
  }

  // ── Monetisation funnel ──────────────────────────────────────────────────────
  // Answers: "Where is revenue dropping off? Which surface converts best?"

  /// Paywall screen is shown to the user.
  /// [source] identifies where the paywall was triggered from (e.g.
  /// 'dashboard', 'settings', 'feature_gate', 'credits_empty').
  Future<void> logPaywallViewed({String source = 'unknown'}) async {
    await _analytics.logEvent(
      name: 'paywall_viewed',
      parameters: {'source': source},
    );
  }

  /// User tapped an "Upgrade" or "Get Premium" button before reaching paywall.
  /// [source] matches the surface that showed the button.
  Future<void> logUpgradeTapped({required String source}) async {
    await _analytics.logEvent(
      name: 'upgrade_tapped',
      parameters: {'source': source},
    );
  }

  /// Purchase flow was initiated (subscribe button pressed).
  Future<void> logSubscriptionStarted({required String packageId}) async {
    await _analytics.logEvent(
      name: 'subscription_started',
      parameters: {'package_id': packageId},
    );
  }

  /// Credit purchase flow was initiated (buy credits button pressed).
  Future<void> logCreditsPurchaseStarted({required String productId}) async {
    await _analytics.logEvent(
      name: 'credits_purchase_started',
      parameters: {'product_id': productId},
    );
  }

  /// Credit purchase completed successfully (one-time in-app purchase, not a subscription).
  Future<void> logCreditsPurchased({
    required String productId,
    required int creditsAmount,
  }) async {
    await _analytics.logEvent(
      name: 'credits_purchased',
      parameters: {
        'product_id': productId,
        'credits_amount': creditsAmount,
      },
    );
  }

  /// Credit purchase failed or was cancelled.
  Future<void> logCreditsPurchaseFailed({required String productId}) async {
    await _analytics.logEvent(
      name: 'credits_purchase_failed',
      parameters: {'product_id': productId},
    );
  }

  /// Purchase completed successfully.
  Future<void> logSubscriptionPurchased({required String packageId}) async {
    await _analytics.logEvent(
      name: 'subscription_purchased',
      parameters: {'package_id': packageId},
    );
    await _analytics.setUserProperty(
        name: 'subscription_tier', value: 'pro');
  }

  /// Purchase failed or was cancelled.
  Future<void> logSubscriptionFailed({required String packageId}) async {
    await _analytics.logEvent(
      name: 'subscription_failed',
      parameters: {'package_id': packageId},
    );
  }

  /// User restored previous purchases successfully.
  Future<void> logPurchasesRestored() async {
    await _analytics.logEvent(name: 'purchases_restored');
    await _analytics.setUserProperty(
        name: 'subscription_tier', value: 'pro');
  }
}
