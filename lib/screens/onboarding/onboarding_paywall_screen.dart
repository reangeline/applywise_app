import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/haptic_service.dart';
import '../../services/revenue_cat_service.dart';
import '../../widgets/app_spinner.dart';
import '../home/home_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';

class OnboardingPaywallScreen extends StatefulWidget {
  const OnboardingPaywallScreen({super.key});

  @override
  State<OnboardingPaywallScreen> createState() =>
      _OnboardingPaywallScreenState();
}

class _OnboardingPaywallScreenState extends State<OnboardingPaywallScreen> {
  Package? _selectedPackage;
  bool _isPurchasing = false;
  bool _isInTrial = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logPaywallViewed(source: 'onboarding_paywall');
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final sub = context.read<SubscriptionProvider>();
    await sub.loadSubscription();

    if (!mounted) return;

    // Select annual plan by default, fall back to first available
    if (sub.packages.isNotEmpty) {
      setState(() {
        _selectedPackage = sub.packages.firstWhere(
          (p) {
            final id = p.identifier.toLowerCase();
            return id.contains('annual') || id.contains('yearly');
          },
          orElse: () => sub.packages.first,
        );
      });
    }

    // Check if the user is already in a trial period (only when SDK is configured)
    if (RevenueCatService().isInitialized) {
      try {
        final info = await Purchases.getCustomerInfo();
        final entitlement = info.entitlements.active[AppConstants.proEntitlement];
        if (entitlement != null && mounted) {
          setState(() {
            _isInTrial = entitlement.periodType == PeriodType.trial;
          });
        }
      } catch (_) {}
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final atsResult = context.read<OnboardingProvider>().atsResult;
    final score = atsResult?.score;
    final totalIssues = atsResult?.totalIssues;

    if (sub.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: AppSpinner()),
      );
    }

    if (sub.packages.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text('Plans not available at the moment.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skipToHome,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isInTrial)
              _buildTrialBanner(),
            _buildHeader(context, score, totalIssues),
            const SizedBox(height: 28),
            _buildFeatures(context),
            const SizedBox(height: 28),
            _buildPlans(context, sub.packages),
            const SizedBox(height: 24),
            _buildPurchaseButton(context),
            const SizedBox(height: 16),
            _buildRestoreButton(context),
            const SizedBox(height: 16),
            _buildSkipButton(context),
            const SizedBox(height: 16),
            _buildLegalText(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Ativar PRO'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _skipToHome,
      ),
    );
  }

  Widget _buildTrialBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined,
              color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are in the free trial period!',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int? score, int? totalIssues) {
    final String headline;
    if (score != null && totalIssues != null) {
      final n = totalIssues;
      headline =
          'Your resume scored $score/100 — fix $n issue${n == 1 ? '' : 's'} free for 7 days';
    } else {
      headline = 'Try Hirefy free for 7 days';
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/icons/logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          headline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Cancel anytime. No commitment.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            '🎉  Try free for 7 days',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Used by professionals who want more interviews',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      (Icons.auto_awesome, 'Unlimited resume optimizations'),
      (Icons.bolt, 'AI suggestions by role and company'),
      (Icons.link, 'LinkedIn profile optimization included'),
      (Icons.bar_chart, 'Track your score evolution'),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(f.$1,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(f.$2,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlans(BuildContext context, List<Package> packages) {
    return Column(
      children: packages.map((pkg) {
        final isSelected = _selectedPackage == pkg;
        final product = pkg.storeProduct;
        final id = pkg.identifier.toLowerCase();
        final isBestValue = id.contains('annual') || id.contains('yearly');

        return Semantics(
          label: '${_formatTitle(product.title)}, ${product.priceString}',
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () {
              HapticService.selection();
              setState(() => _selectedPackage = pkg);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? AppTheme.cardShadow : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _formatTitle(product.title),
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                            if (isBestValue) ...[
                              _badge('BEST VALUE', AppTheme.primaryColor),
                              _badge('SAVE 33%',
                                  AppTheme.successColor),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.priceString,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    final priceLabel = _selectedPackage != null
        ? '${_selectedPackage!.storeProduct.priceString}'
            '/${_periodLabel(_selectedPackage!.packageType)}'
        : '';

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing ? null : _purchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isPurchasing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Start free for 7 days${priceLabel.isNotEmpty ? ' · $priceLabel after' : ''}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }

  Widget _buildRestoreButton(BuildContext context) {
    return TextButton(
      onPressed: _isPurchasing ? null : _restore,
      child: const Text('Restore Purchase'),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return TextButton(
      onPressed: _skipToHome,
      style: TextButton.styleFrom(foregroundColor: AppTheme.textTertiary),
      child: const Text('Skip for now'),
    );
  }

  Widget _buildLegalText(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
        children: [
          const TextSpan(
            text:
                'By subscribing, you accept our ',
          ),
          TextSpan(
            text: 'Terms of Service',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen()),
                  ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()),
                  ),
          ),
          const TextSpan(text: '. Renews automatically. Cancel anytime.'),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _purchase() async {
    if (_selectedPackage == null) return;
    setState(() => _isPurchasing = true);
    final packageId = _selectedPackage!.identifier;
    final sub = context.read<SubscriptionProvider>();
    try {
      await AnalyticsService.instance.logSubscriptionStarted(
        packageId: packageId,
      );
      final success = await sub.purchasePackage(_selectedPackage!);
      if (!mounted) return;
      if (success) {
        await HapticService.heavy();
        await AnalyticsService.instance.logSubscriptionPurchased(
          packageId: packageId,
        );
        _navigateToHome();
      } else {
        await HapticService.error();
        await AnalyticsService.instance.logSubscriptionFailed(
          packageId: packageId,
        );
        _showError('Purchase not completed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      await HapticService.error();
      _showError('Error processing payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      final sub = context.read<SubscriptionProvider>();
      final restored = await sub.restorePurchases();
      if (!mounted) return;
      if (restored) {
        await AnalyticsService.instance.logPurchasesRestored();
        _navigateToHome();
      } else {
        _showError('No purchases found to restore.');
      }
    } catch (_) {
      if (mounted) _showError('Error restoring purchase. Please try again.');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _skipToHome() {
    context.read<OnboardingProvider>().clear();
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatTitle(String raw) {
    // RevenueCat sometimes appends "  (Hirefy)" — strip it
    return raw.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
  }

  String _periodLabel(PackageType type) {
    return switch (type) {
      PackageType.monthly => 'mo',
      PackageType.threeMonth => 'qtr',
      PackageType.sixMonth => '6mo',
      PackageType.annual => 'yr',
      _ => 'period',
    };
  }
}
