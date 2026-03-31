import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/analytics_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class OnboardingLoginScreen extends StatefulWidget {
  const OnboardingLoginScreen({super.key});

  @override
  State<OnboardingLoginScreen> createState() => _OnboardingLoginScreenState();
}

class _OnboardingLoginScreenState extends State<OnboardingLoginScreen> {
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
                Icons.login_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to access your saved analyses and resume history.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
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
          side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ),
        const Expanded(child: Divider()),
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
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── Auth handlers ────────────────────────────────────────────────────────

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
    final subscriptionProvider = context.read<SubscriptionProvider>();

    await AnalyticsService.instance.logLogin();
    if (authProvider.user != null) {
      await AnalyticsService.instance.setUserId(authProvider.user!.id);
      await subscriptionProvider.loadSubscription();
      if (mounted) {
        await AnalyticsService.instance.setUserProperty(
          name: 'subscription_tier',
          value: subscriptionProvider.isPro ? 'pro' : 'free',
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
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
