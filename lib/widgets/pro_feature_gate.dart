import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../screens/subscription/paywall_screen.dart';

class ProFeatureGate extends StatelessWidget {
  final bool isPro;
  final Widget child;

  const ProFeatureGate({
    super.key,
    required this.isPro,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isPro) {
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
                  'Upgrade to Premium to access unlimited resume optimizations and premium features',
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
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Upgrade Now'),
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
