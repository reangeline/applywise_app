import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/resume_service.dart';
import '../auth/signup_screen.dart';
import 'onboarding_paywall_screen.dart';

class OnboardingSignupScreen extends StatefulWidget {
  const OnboardingSignupScreen({super.key});

  @override
  State<OnboardingSignupScreen> createState() =>
      _OnboardingSignupScreenState();
}

class _OnboardingSignupScreenState extends State<OnboardingSignupScreen> {
  bool _isLoading = false;
  String? _activeProvider; // 'apple' | 'google'

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 40),
              if (_isLoading) ...[
                _buildLoadingState(),
              ] else ...[
                _buildAppleButton(),
                const SizedBox(height: 16),
                _buildGoogleButton(),
                const SizedBox(height: 16),
                _buildDivider(),
                const SizedBox(height: 16),
                _buildEmailButton(),
              ],
              const SizedBox(height: 32),
              _buildLegal(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_open_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'See Full Analysis',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Save your analysis and see the full details',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
        // Benefits row
        _buildBenefitItem(
            Icons.check_circle_outline, 'See all issues found'),
        const SizedBox(height: 8),
        _buildBenefitItem(
            Icons.check_circle_outline, 'Get detailed fix suggestions'),
        const SizedBox(height: 8),
        _buildBenefitItem(
            Icons.check_circle_outline, 'Track your resume progress'),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: AppTheme.primaryColor),
        const SizedBox(height: 20),
        Text(
          _activeProvider == 'apple'
              ? 'Signing in with Apple...'
              : _activeProvider == 'google'
                  ? 'Signing in with Google...'
                  : 'Authenticating...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAppleButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.apple, size: 22),
        label: const Text(
          'Continue with Apple',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: _handleAppleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }

  Widget _buildEmailButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.email_outlined, size: 20),
        label: const Text(
          'Continue with Email',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: _handleEmailSignUp,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLegal() {
    return Text(
      'By creating an account you agree to our Terms of Service and Privacy Policy.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white38,
          ),
      textAlign: TextAlign.center,
    );
  }

  // ─── Auth handlers ────────────────────────────────────────────────────────

  void _handleEmailSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _activeProvider = 'apple';
    });
    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.signInWithApple();
      if (!mounted) return;
      if (result.success) {
        await _onAuthSuccess();
      } else {
        _showError(result.error ?? 'Failed to sign in with Apple. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error signing in with Apple. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _activeProvider = 'google';
    });
    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.signInWithGoogle();
      if (!mounted) return;
      if (result.success) {
        await _onAuthSuccess();
      } else {
        _showError(result.error ?? 'Failed to sign in with Google. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error signing in with Google. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAuthSuccess() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    // Analytics
    await AnalyticsService.instance.logSignUp();
    if (authProvider.user != null) {
      await AnalyticsService.instance.setUserId(authProvider.user!.id);
      await AnalyticsService.instance.setUserProperty(
        name: 'subscription_tier',
        value: 'free',
      );
    }

    // Load subscription
    await subscriptionProvider.loadSubscription();
    if (!mounted) return;

    // For PDF-based onboarding: create the resume via resumes/manual using the
    // parsed_data already obtained from parse-pdf (non-fatal).
    final parsedResumeData = onboardingProvider.parsedResumeData;
    if (parsedResumeData != null) {
      try {
        await ResumeService().createManualResume(resumeData: parsedResumeData);
      } catch (_) {
        // Non-fatal: user can still proceed even if resume creation fails.
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppTransitions.slideUp(const OnboardingPaywallScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}

// ─── Exported helpers so auth_provider can call them without circular imports ──

/// Gets the Apple ID credential.  Called by [AuthProvider.signInWithApple].
Future<AuthorizationCredentialAppleID> getAppleCredential() {
  return SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
  );
}

/// Signs in with Google and returns the [GoogleSignInAuthentication].
/// Returns null if the user cancels.
Future<GoogleSignInAuthentication?> getGoogleAuth() async {
  final googleSignIn = GoogleSignIn();
  final account = await googleSignIn.signIn();
  return account?.authentication;
}
