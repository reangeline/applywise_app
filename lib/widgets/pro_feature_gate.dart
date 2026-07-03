import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../config/theme.dart';
import '../config/transitions.dart';
import '../screens/subscription/credits_paywall_screen.dart';

class ProFeatureGate extends StatelessWidget {
  final bool isPro;
  final int credits;
  final Widget child;

  const ProFeatureGate({
    super.key,
    required this.isPro,
    this.credits = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Liberar se tem assinatura OU créditos
    if (isPro || credits > 0) {
      return child;
    }

    return Stack(
      children: [
        // Blurred content
        AbsorbPointer(
          absorbing: true,
          child: Opacity(
            opacity: 0.3,
            child: child,
          ),
        ),
        // Lock overlay
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Premium Feature',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Get Premium for unlimited optimizations or buy credits to optimize your resume',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      RevenueCatUI.presentPaywall();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Upgrade Now'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        AppTransitions.slideUp(const CreditsPaywallScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    child: const Text('Buy Credits'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
