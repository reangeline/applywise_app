class AppConstants {
  // API Configuration — injetado via --dart-define-from-file
  // Dev:  config/dev.json  |  Prod: config/prod.json
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bo0aj4wdk2.execute-api.us-east-1.amazonaws.com',
  );

  // API Endpoints
  static const String signUpEndpoint = '/api/v1/auth/signup';
  static const String signInEndpoint = '/api/v1/auth/signin';
  static const String refreshTokenEndpoint = '/api/v1/auth/refresh';
  static const String confirmSignUpEndpoint = '/api/v1/auth/confirm';
  static const String resendCodeEndpoint = '/api/v1/auth/resend-code';
  static const String forgotPasswordEndpoint = '/api/v1/auth/forgot-password';
  static const String confirmForgotPasswordEndpoint = '/api/v1/auth/confirm-forgot-password';
  static const String subscriptionEndpoint = '/api/v1/subscription';
  static const String checkoutEndpoint = '/api/v1/subscription/checkout';
  static const String optimizeResumeEndpoint = '/api/v1/resumes/optimize';
  static const String linkedinOptimizeEndpoint = '/api/v1/resumes/linkedin/optimize';
  static const String optimizeJobsEndpoint = '/api/v1/resumes/optimize/jobs';
  static const String resumesEndpoint = '/api/v1/resumes';
  static const String createManualResumeEndpoint = '/api/v1/resumes/manual';
  static const String parsePdfResumeEndpoint = '/api/v1/resumes/parse-pdf';
  static const String userMeEndpoint = '/api/v1/users/me';
  static const String deleteAccountEndpoint = '/api/v1/users/me';
  static const String socialAuthEndpoint = '/api/v1/auth/social';

  // Pipeline endpoints
  static const String pipelineEndpoint = '/api/v1/pipeline';
  static const String pipelineCoachEndpoint = '/api/v1/pipeline';


  // RevenueCat Configuration — injetado via --dart-define-from-file
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUE_CAT_API_KEY',
    defaultValue: 'appl_KfkcroykzlCplzCmUOBTPwWAlDS',
  );
  
  // RevenueCat Products
  static const String monthlyProductId = 'monthly';
  static const String threeMonthProductId = 'three_month';
  static const String yearlyProductId = 'yearly';
  
  // RevenueCat Entitlement
  static const String proEntitlement = 'ApplyWise Premium';

  // Subscription Plans
  static const String freePlan = 'free';
  static const String premiumPlan = 'premium';

  // Feature Limits
  static const int freeOptimizationsPerMonth = 1;
  static const int premiumOptimizationsPerMonth = -1; // unlimited

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String isFirstLaunchKey = 'is_first_launch';

  // App Info
  static const String appName = 'Hirefy';
  static const String appVersion = '1.0.0';
  static const String termsVersion = '1.0';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
