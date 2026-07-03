import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/analytics_service.dart';
import '../../services/revenue_cat_service.dart';
import '../../widgets/app_spinner.dart';
import '../../config/transitions.dart';
import '../../providers/subscription_provider.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';


class CreditsPaywallScreen extends StatefulWidget {
  const CreditsPaywallScreen({super.key});

  @override
  State<CreditsPaywallScreen> createState() => _CreditsPaywallScreenState();
}

class _CreditsPaywallScreenState extends State<CreditsPaywallScreen> {
  final RevenueCatService _revenueCatService = RevenueCatService();
  
  List<StoreProduct> _products = [];
  StoreProduct? _selectedProduct;
  bool _isPurchasing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logPaywallViewed(source: 'credits');
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      
      // Carregar produtos de créditos do RevenueCat
      final products = await _revenueCatService.getCreditProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          // Selecionar o produto do meio por padrão
          if (products.isNotEmpty) {
            _selectedProduct = products.length > 1 ? products[1] : products.first;
          }
        });
        
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Credits'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: AppSpinner())
          : _products.isEmpty
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildFeatures(),
                      const SizedBox(height: 32),
                      _buildProducts(),
                      const SizedBox(height: 24),
                      _buildPurchaseButton(),
                      const SizedBox(height: 16),
                      _buildInfoText(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          const Text('No products available'),
          const SizedBox(height: 8),
          const Text(
            'Please try again later',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 64,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Buy Optimization Credits',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Purchase credits to optimize your resumes',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    final features = [
      {'icon': Icons.check_circle, 'text': 'AI-Powered Resume Optimization'},
      {'icon': Icons.trending_up, 'text': 'Improve ATS Score'},
      {'icon': Icons.star, 'text': 'Stand Out from Competition'},
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
                  size: 20,
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

  Widget _buildProducts() {
    // Ordenar produtos por identificador
    final sortedProducts = List<StoreProduct>.from(_products)
      ..sort((a, b) => a.identifier.compareTo(b.identifier));

    return Column(
      children: sortedProducts.map((product) {
        final isSelected = _selectedProduct == product;
        final credits = _extractCreditsFromIdentifier(product.identifier);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Detectar se é o melhor valor (credits_20)
        final isBestValue = product.identifier.contains('20');

        return GestureDetector(
          onTap: () => setState(() => _selectedProduct = product),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.darkBorder : AppTheme.borderColor),
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
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.textTertiary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$credits Credits',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isBestValue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
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
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$credits Resume Optimizations',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  product.priceString,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  int _extractCreditsFromIdentifier(String identifier) {
    // Extrair número do identificador (credits_5 -> 5)
    final match = RegExp(r'(\d+)').firstMatch(identifier);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing || _selectedProduct == null
            ? null
            : _handlePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
        ),
        child: _isPurchasing
            ? const AppSpinnerSmall()
            : Text(
                'Purchase ${_extractCreditsFromIdentifier(_selectedProduct?.identifier ?? '')} Credits',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoText() {
    final textStyle = Theme.of(context).textTheme.bodySmall;
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
            text:
                'Credits are one-time purchases and do not auto-renew. They never expire. By purchasing you agree to our ',
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
    if (_selectedProduct == null) return;

    setState(() => _isPurchasing = true);

    try {
      final credits = _extractCreditsFromIdentifier(_selectedProduct!.identifier);

      AnalyticsService.instance.logCreditsPurchaseStarted(
        productId: _selectedProduct!.identifier,
      );

      final success = await _revenueCatService.purchaseCreditProduct(_selectedProduct!);
      
      if (!mounted) return;

      setState(() => _isPurchasing = false);

      if (success) {
        AnalyticsService.instance.logCreditsPurchased(
          productId: _selectedProduct!.identifier,
          creditsAmount: credits,
        );
        
        // Aguardar um pouco para o webhook processar
        await Future.delayed(const Duration(seconds: 2));
        
        // Recarregar créditos do provider
        if (mounted) {
          await context.read<SubscriptionProvider>().refreshCredits();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully purchased $credits credits!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );

        // Fechar paywall
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true); // Retorna true para indicar sucesso
        }
      } else {
        AnalyticsService.instance.logCreditsPurchaseFailed(
          productId: _selectedProduct!.identifier,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isPurchasing = false);

      // Verificar se o usuário cancelou
      if (e is PlatformException && e.code == '1') {
        // Usuário cancelou, não mostrar erro
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
