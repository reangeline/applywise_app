import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../config/theme.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/app_spinner.dart';
import '../../config/transitions.dart';
import '../../services/analytics_service.dart';
import '../../services/haptic_service.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Package? _selectedPackage;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logPaywallViewed(source: 'paywall_screen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackages();
    });
  }

  Future<void> _loadPackages() async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    
    await subscriptionProvider.loadSubscription();
    
    if (mounted && subscriptionProvider.packages.isNotEmpty) {
      setState(() {
        // Selecionar plano anual por padrão (melhor valor)
        _selectedPackage = subscriptionProvider.packages.firstWhere(
          (p) {
            final id = p.identifier.toLowerCase();
            return id.contains('annual') || id.contains('yearly');
          },
          orElse: () => subscriptionProvider.packages.first,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    if (subscriptionProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upgrade to PRO'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: AppSpinner(),
        ),
      );
    }

    if (subscriptionProvider.packages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upgrade to PRO'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              const Text('No plans available'),
              const SizedBox(height: 8),
              const Text(
                'Please try again later',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPackages,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to PRO'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFeatures(),
            const SizedBox(height: 32),
            _buildPlans(subscriptionProvider.packages),
            const SizedBox(height: 24),
            _buildPurchaseButton(),
            const SizedBox(height: 16),
            _buildRestoreButton(),
            const SizedBox(height: 16),
            _buildLegalText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/icons/logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock PRO Features',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Land more interviews with AI-powered resume and LinkedIn optimization',
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
            Text(
              'Join job seekers landing more interviews',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    final features = [
      {'icon': Icons.auto_awesome, 'text': 'Unlimited Resume Optimizations'},
      {'icon': Icons.bolt, 'text': 'AI-Powered Suggestions'},
      {'icon': Icons.link, 'text': 'LinkedIn Profile Optimization included'},

    ];

    return Column(
      children: features.map((feature) {
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
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature['text'] as String,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlans(List<Package> packages) {
    return Column(
      children: packages.map((package) {
        final isSelected = _selectedPackage == package;
        final product = package.storeProduct;
        
        // Detectar se é anual/yearly para mostrar desconto
        String? discount;
        final identifier = package.identifier.toLowerCase();
        final isBestValue = identifier.contains('annual') || identifier.contains('yearly');
        if (isBestValue) {
          discount = 'SAVE 33%';
        }

        return Semantics(
          label: '${_formatTitle(product.title)}, ${product.priceString}${isSelected ? ", selected" : ""}',
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () {
              HapticService.selection();
              setState(() => _selectedPackage = package);
            },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.outline,
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
                const SizedBox(width: 16),
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isBestValue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BEST VALUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (discount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                discount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.priceString,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isBestValue) ...[
                      const SizedBox(height: 2),
                      Text(
                        _monthlyEquivalent(package),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      }).toList(),
    );
  }

  String _formatTitle(String title) {
    // Remover texto entre parênteses (nome do app)
    final cleaned = title.split('(').first.trim();
    return cleaned;
  }

  String _monthlyEquivalent(Package package) {
    final monthly = package.storeProduct.price / 12;
    final priceStr = package.storeProduct.priceString;
    final match = RegExp(r'^[^\d]+').firstMatch(priceStr);
    final symbol = match?.group(0) ?? r'$';
    return 'just $symbol${monthly.toStringAsFixed(2)}/month';
  }

  String _buildButtonLabel() {
    if (_selectedPackage == null) return 'Subscribe Now';
    final product = _selectedPackage!.storeProduct;
    final identifier = _selectedPackage!.identifier.toLowerCase();
    final String period;
    if (identifier.contains('annual') || identifier.contains('yearly')) {
      period = '/year';
    } else if (identifier.contains('quarter') || identifier.contains('tri')) {
      period = '/3 months';
    } else if (identifier.contains('month')) {
      period = '/month';
    } else {
      period = '';
    }
    return 'Get PRO – ${product.priceString}$period';
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing || _selectedPackage == null
            ? null
            : _handlePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
        ),
        child: _isPurchasing
            ? const AppSpinnerSmall()
            : Text(
                _buildButtonLabel(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _isPurchasing ? null : _handleRestore,
      child: const Text('Restore Purchases'),
    );
  }

  Widget _buildLegalText() {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textTertiary,
    );
    final linkStyle = textStyle?.copyWith(
      color: AppTheme.primaryColor,
      decoration: TextDecoration.underline,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textStyle,
        children: [
          const TextSpan(
            text: 'Auto-renewable subscription. Cancel anytime. By subscribing you agree to our ',
          ),
          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                    context,
                    AppTransitions.slideRight(TermsOfServiceScreen()),
                  ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                    context,
                    AppTransitions.slideRight(PrivacyPolicyScreen()),
                  ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) return;

    setState(() => _isPurchasing = true);

    final packageId = _selectedPackage!.identifier;
    AnalyticsService.instance.logSubscriptionStarted(packageId: packageId);

    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );

    final success = await subscriptionProvider.purchasePackage(_selectedPackage!);

    if (!mounted) return;

    setState(() => _isPurchasing = false);

    if (success) {
      HapticService.heavy();
      AnalyticsService.instance.logSubscriptionPurchased(packageId: packageId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Welcome to PRO!'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );

      // Fechar paywall
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      HapticService.error();
      AnalyticsService.instance.logSubscriptionFailed(packageId: packageId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase failed. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isPurchasing = true);

    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );

    final success = await subscriptionProvider.restorePurchases();

    if (!mounted) return;

    setState(() => _isPurchasing = false);

    if (success) {
      HapticService.medium();
      AnalyticsService.instance.logPurchasesRestored();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Purchases restored!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No purchases found to restore'),
        ),
      );
    }
  }
}
