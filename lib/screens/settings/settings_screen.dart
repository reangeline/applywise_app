import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/pipeline_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/transitions.dart';
import '../../services/analytics_service.dart';
import '../../widgets/app_spinner.dart';
import '../onboarding/onboarding_screen.dart';
import '../subscription/paywall_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/refund_policy_screen.dart';
import '../legal/cookie_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileCard(context, authProvider, subscriptionProvider),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Subscription',
                items: [
                  if (!subscriptionProvider.isPro)
                    _buildSettingItem(
                      context,
                      icon: Icons.workspace_premium,
                      title: 'Upgrade to Premium',
                      subtitle: 'Unlock all features',
                      color: AppTheme.primaryColor,
                      onTap: () {
                        AnalyticsService.instance.logUpgradeTapped(source: 'settings');
                        Navigator.of(context).push(
                          AppTransitions.slideUp(const PaywallScreen()),
                        );
                      },
                    ),
                  _buildSettingItem(
                    context,
                    icon: Icons.restore,
                    title: 'Restore Purchases',
                    subtitle: 'Restore your premium access',
                    onTap: () => _handleRestore(context, subscriptionProvider),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'General',
                items: [
                  const _NotificationToggleItem(),
                  const _DarkModeToggleItem(),
                  _buildSettingItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'contact@hirefy.careers',
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'contact@hirefy.careers',
                        queryParameters: {'subject': 'Help & Support – Hirefy'},
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  // Group policies and terms inside an ExpansionTile
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      collapsedIconColor: AppTheme.textTertiary.withOpacity(0.9),
                      iconColor: AppTheme.textTertiary.withOpacity(0.9),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.policy,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Policies & Terms',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.privacy_tip_outlined, size: 18),
                          title: const Text('Privacy Policy'),
                          onTap: () => Navigator.push(
                            context,
                            AppTransitions.slideRight(PrivacyPolicyScreen()),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined, size: 18),
                          title: const Text('Terms of Service'),
                          onTap: () => Navigator.push(
                            context,
                            AppTransitions.slideRight(TermsOfServiceScreen()),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.attach_money, size: 18),
                          title: const Text('Refund Policy'),
                          onTap: () => Navigator.push(
                            context,
                            AppTransitions.slideRight(RefundPolicyScreen()),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.cookie_outlined, size: 18),
                          title: const Text('Cookie Policy'),
                          onTap: () => Navigator.push(
                            context,
                            AppTransitions.slideRight(CookiePolicyScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Account',
                items: [
                  _buildSettingItem(
                    context,
                    icon: Icons.logout,
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    color: AppTheme.errorColor,
                    onTap: () => _handleLogout(context, authProvider),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and data',
                    color: AppTheme.errorColor,
                    onTap: () => _handleDeleteAccount(context, authProvider),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Version ${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthProvider authProvider, SubscriptionProvider subscriptionProvider) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.user?.name ?? 'User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              authProvider.user?.email ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        subscriptionProvider.isPro
                            ? Icons.workspace_premium
                            : Icons.workspace_premium_outlined,
                        size: 16,
                        color: subscriptionProvider.isPro
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subscriptionProvider.isPro ? 'Premium' : 'Free',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subscriptionProvider.isPro
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showEditProfileSheet(context, authProvider),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color ?? AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        currentName: authProvider.user?.name ?? '',
        authProvider: authProvider,
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, SubscriptionProvider subscriptionProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: AppSpinner(),
      ),
    );

    final success = await subscriptionProvider.restorePurchases();

    if (!context.mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Purchases restored successfully!'
              : 'No purchases found to restore',
        ),
        backgroundColor: success ? AppTheme.successColor : null,
      ),
    );
  }

  Future<void> _handleDeleteAccount(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppSpinner()),
    );

    final result = await authProvider.deleteAccount();

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    if (result.success) {
      await _clearSessionCaches(context);

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        AppTransitions.fadeSlide(const OnboardingScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to delete account. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AnalyticsService.instance.logLogout();
      await authProvider.signOut();

      if (!context.mounted) return;

      await _clearSessionCaches(context);

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        AppTransitions.fadeSlide(const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _clearSessionCaches(BuildContext context) async {
    final pipelineProvider = context.read<PipelineProvider>();
    final resumeProvider = context.read<ResumeProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    await pipelineProvider.reset();
    resumeProvider.reset();
    subscriptionProvider.reset();
    notificationProvider.reset();
    onboardingProvider.clear();
  }
}

// ── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  final AuthProvider authProvider;

  const _EditProfileSheet({
    required this.currentName,
    required this.authProvider,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await widget.authProvider.updateProfile(name: name);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to update profile. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Toggle ──────────────────────────────────────────────────────

class _NotificationToggleItem extends StatefulWidget {
  const _NotificationToggleItem();

  @override
  State<_NotificationToggleItem> createState() =>
      _NotificationToggleItemState();
}

class _NotificationToggleItemState extends State<_NotificationToggleItem> {
  bool _loading = false;

  Future<void> _handleToggle(NotificationProvider provider, bool value) async {
    if (_loading) return;

    if (value) {
      // Check OS permission before enabling
      final status = await provider.getPermissionStatus();
      if (status == AuthorizationStatus.denied) {
        if (!mounted) return;
        _showPermissionBlockedDialog();
        return;
      }
    }

    setState(() => _loading = true);
    await provider.setNotificationsEnabled(value);
    if (mounted) setState(() => _loading = false);
  }

  void _showPermissionBlockedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notifications Blocked'),
        content: const Text(
          'Notifications are blocked by your device.\n\n'
          'To enable them, go to your device Settings and allow notifications for this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Open system app settings (works on iOS; Android shows store page fallback)
              final uri = Uri.parse('app-settings:');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  provider.notificationsEnabled
                      ? 'Push notifications are enabled'
                      : 'Push notifications are disabled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 24,
              height: 24,
              child: AppSpinner(size: 24),
            )
          else
            Switch.adaptive(
              value: provider.notificationsEnabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => _handleToggle(provider, v),
            ),
        ],
      ),
    );
  }
}

// ── Dark Mode Toggle ─────────────────────────────────────────────────────────

class _DarkModeToggleItem extends StatelessWidget {
  const _DarkModeToggleItem();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brightness = MediaQuery.of(context).platformBrightness;
    final effectivelyDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            brightness == Brightness.dark);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  effectivelyDark ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      themeProvider.isSystem
                          ? 'Following system setting'
                          : effectivelyDark
                              ? 'Dark mode is on'
                              : 'Light mode is on',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: effectivelyDark,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => themeProvider.setThemeMode(
                    v ? ThemeMode.dark : ThemeMode.light),
              ),
            ],
          ),
        ),
        // "Use system setting" link
        if (!themeProvider.isSystem)
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                child: Text(
                  'Use system setting',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
