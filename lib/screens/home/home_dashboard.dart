import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/resume_provider.dart';
import '../subscription/paywall_screen.dart';
import '../auth/verify_code_screen.dart';
import '../resume/optimize_info_screen.dart';
import '../resume/linkedin_opt_select_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

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
    });
  }

  Future<void> _loadData() async {
    final resumeProvider = Provider.of<ResumeProvider>(context, listen: false);
    await resumeProvider.loadResumes();
  }

  Future<void> _checkEmailVerification() async {
    print('🔍 Iniciando verificação de email...');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Consultar backend via /user/me (fonte da verdade!)
      final verified = await authProvider.fetchEmailVerifiedFromBackend();
      
      print('✅ Email verificado: $verified');
      print('📧 Banner será ${verified ? "ESCONDIDO" : "EXIBIDO"}');
      
      if (mounted) {
        setState(() {
          _emailVerified = verified;
        });
      }
    } catch (e) {
      print('❌ Erro ao verificar email: $e');
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
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
                _buildStatsCards(resumeProvider),
                const SizedBox(height: 24),
                _buildQuickActions(subscriptionProvider),
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
                MaterialPageRoute(
                  builder: (_) => VerifyCodeScreen(
                    email: authProvider.user?.email ?? '',
                    password: '', // Não precisa da senha - usuário já está logado
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(SubscriptionProvider subscriptionProvider) {
    final isPro = subscriptionProvider.isPro;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPro ? AppTheme.primaryGradient : null,
        color: isPro ? null : AppTheme.surfaceColor,
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
                    isPro ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                    color: isPro ? Colors.white : AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPro ? 'Premium Active' : 'Free Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isPro ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Limited',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPro
                ? 'Unlimited resume optimizations & premium features'
                : '1 optimization per month',
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
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
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

  Widget _buildStatsCards(ResumeProvider resumeProvider) {
    final resumeCount = resumeProvider.resumes.length;
    final avgScore = resumeProvider.resumes.isEmpty
        ? 0.0
        : resumeProvider.resumes.map((r) => r.score).reduce((a, b) => a + b) / resumeCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.description,
            title: 'Resumes',
            value: resumeCount.toString(),
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            title: 'Avg Score',
            value: avgScore.toStringAsFixed(1),
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
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
            onTap: () {
              // Intentionally empty for now — only the field
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
              MaterialPageRoute(builder: (_) => const LinkedInOptSelectScreen()),
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
              MaterialPageRoute(builder: (_) => const OptimizeInfoScreen()),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
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
}
