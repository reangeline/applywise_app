import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/pipeline_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/pipeline_section.dart';
import '../../widgets/skeleton_loader.dart';
import '../../services/widget_service.dart';
import '../subscription/paywall_screen.dart';
import '../subscription/credits_paywall_screen.dart';
import '../auth/verify_code_screen.dart';
import '../resume/optimize_info_screen.dart';
import '../resume/linkedin_opt_select_screen.dart';
import 'notifications_screen.dart';

class HomeDashboard extends StatefulWidget {
  final VoidCallback? onAddJobTap;

  const HomeDashboard({super.key, this.onAddJobTap});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _emailVerified = true; // Assumir true por padrão

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkEmailVerification();
      _initializeNotifications();
    });
  }
  
  Future<void> _initializeNotifications() async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      if (!notificationProvider.isInitialized) {
        await notificationProvider.initialize();
      }
    } catch (e) {
      // Não falhar - app funciona sem notificações
    }
  }

  Future<void> _loadData({bool force = false}) async {
    debugPrint('🟠 HomeDashboard._loadData(force=$force) — hashCode=${hashCode}');
    final resumeProvider = Provider.of<ResumeProvider>(context, listen: false);
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final pipelineProvider =
        Provider.of<PipelineProvider>(context, listen: false);

    await Future.wait([
      resumeProvider.loadResumes(force: force),
      subscriptionProvider.loadSubscription(force: force),
      if (force) pipelineProvider.refresh(),
    ]);

    // Push latest data to iOS home screen widget
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      WidgetService.update(
        userName: authProvider.user?.name.split(' ').first ?? 'Hirefy',
        isPro: subscriptionProvider.isPro,
        credits: subscriptionProvider.credits,
        resumeCount: resumeProvider.resumes.length,
      );
    }
  }

  Future<void> _checkEmailVerification() async {

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Consultar backend via /user/me (fonte da verdade!)
      final verified = await authProvider.fetchEmailVerifiedFromBackend();


      if (mounted) {
        setState(() {
          _emailVerified = verified;
        });
      }
    } catch (e) {
      // Se der erro, assumir que está verificado (evitar bloquear usuário)
      if (mounted) {
        setState(() {
          _emailVerified = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final resumeProvider = Provider.of<ResumeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: (subscriptionProvider.isLoading && subscriptionProvider.subscription == null) ||
               (resumeProvider.isLoading && resumeProvider.resumes.isEmpty)
            ? const HomeDashboardSkeleton()
            : RefreshIndicator(
          onRefresh: () => _loadData(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(authProvider),

                // Banner de verificação de email (só aparece se não verificado)
                if (!_emailVerified) ...[
                  const SizedBox(height: 16),
                  _buildEmailVerificationBanner(authProvider),
                ],

                const SizedBox(height: 24),
                _buildSubscriptionCard(subscriptionProvider),
                const SizedBox(height: 24),
                PipelineSection(onAddJobTap: widget.onAddJobTap),
                const SizedBox(height: 24),
                _buildQuickActions(subscriptionProvider),
                const SizedBox(height: 24),
                _buildOptimizationSuggestions(resumeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailVerificationBanner(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mail_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your inbox to unlock all features',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                AppTransitions.fadeSlide(
                  VerifyCodeScreen(
                    email: authProvider.user?.email ?? '',
                    password: '',
                    name: authProvider.user?.name ?? '',
                  ),
                ),
              );

              // Se voltou com sucesso (email verificado), recarregar status
              if (result == true) {
                _checkEmailVerification();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Verify',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        // Fallback se o provider não estiver inicializado
        final unreadCount = notificationProvider.isInitialized 
            ? notificationProvider.unreadCount 
            : 0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.user?.name ?? 'User',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
            Semantics(
              label: unreadCount > 0
                  ? 'Notifications, $unreadCount unread'
                  : 'Notifications',
              button: true,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.fadeSlide(const NotificationsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard(SubscriptionProvider subscriptionProvider) {
    final isPro = subscriptionProvider.isPro;
    final credits = subscriptionProvider.credits;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPro ? AppTheme.primaryGradient : null,
        color: isPro ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isPro
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    color: isPro ? Colors.white : AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPro ? 'Premium Active' : 'Free Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isPro
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              // Sempre mostrar créditos se houver
              if (credits > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPro
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: isPro ? Colors.white : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$credits credits',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  isPro ? Colors.white : AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPro
                ? credits > 0
                    ? 'Unlimited optimizations + $credits bonus credits reserved'
                    : 'Unlimited resume optimizations & premium features'
                : '$credits optimization${credits != 1 ? 's' : ''} available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isPro ? Colors.white70 : AppTheme.textSecondary,
                ),
          ),
          if (!isPro) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  AnalyticsService.instance.logUpgradeTapped(source: 'dashboard');
                  Navigator.of(context).push(
                    AppTransitions.slideUp(const PaywallScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Upgrade to Premium'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptimizationSuggestions(ResumeProvider resumeProvider) {
    // Coletar todas as sugestões dos currículos otimizados
    final allSuggestions = <String>[];

    for (final resume in resumeProvider.resumes) {
      if (resume.type == 'optimized' && resume.suggestions != null) {
        allSuggestions.addAll(resume.suggestions!);
      }
    }

    // Se não houver sugestões, mostrar mensagem
    if (allSuggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No optimization suggestions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optimize your resume to get personalized suggestions',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    // Mostrar as sugestões
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Optimization Suggestions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Mostrar no máximo as 5 últimas sugestões
        ...allSuggestions
            .take(5)
            .map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
        if (allSuggestions.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Semantics(
              button: true,
              child: GestureDetector(
                onTap: () => _showAllSuggestions(context, allSuggestions),
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.expand_more,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${allSuggestions.length - 5} more suggestions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ],
    );
  }

  void _showAllSuggestions(BuildContext context, List<String> suggestions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All Optimization Suggestions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      '${suggestions.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Tips to improve your resume and increase your ATS score',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestions[index],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(SubscriptionProvider subscriptionProvider) {
    final isPro = subscriptionProvider.isPro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (!isPro) ...[
          _buildActionCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Buy Optimizations',
            description: 'Purchase additional optimizations',
            color: AppTheme.accentColor,
            onTap: () async {
              final result = await Navigator.of(context).push(
                AppTransitions.slideUp(const CreditsPaywallScreen()),
              );

              // Se a compra foi bem-sucedida, recarregar créditos
              if (result == true && mounted) {
                await subscriptionProvider.refreshCredits();
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        _buildActionCard(
          icon: Icons.person_search,
          title: 'AI LinkedIn Optimization',
          description: 'Optimize your LinkedIn profile with AI',
          color: AppTheme.primaryColor,
          onTap: () {
            Navigator.of(context).push(
              AppTransitions.fadeSlide(const LinkedInOptSelectScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.info_outline,
          title: 'How Optimization Works',
          description: 'Learn how our AI improves your CV',
          color: AppTheme.secondaryColor,
          onTap: () {
            Navigator.of(context).push(
              AppTransitions.fadeSlide(const OptimizeInfoScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
