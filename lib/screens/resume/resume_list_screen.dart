import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../widgets/app_spinner.dart';
import '../../providers/resume_provider.dart';
import '../../models/resume.dart';
import '../../services/analytics_service.dart';
import '../../services/pdf_service.dart';
import 'resume_manual_form.dart';
import 'linkedin_carousel_screen.dart';

class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key});

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    // Defer loading until after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResumes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResumes() async {
    final resumeProvider = Provider.of<ResumeProvider>(context, listen: false);
    await resumeProvider.loadResumes();
  }

  bool _hasOptimizedData(Resume resume) {
    return (resume.optimizedText?.isNotEmpty == true) ||
        (resume.suggestions?.isNotEmpty == true) ||
        resume.score != null;
  }

  bool _isOptimizedResume(Resume resume) {
    return resume.type != 'manual' || _hasOptimizedData(resume);
  }

  bool _isManualResume(Resume resume) {
    return !_isOptimizedResume(resume);
  }

  bool _isLinkedInResume(Resume resume) => resume.type == 'linkedin';

  void _openLinkedInCarousel(Resume resume) {
    if (resume.linkedInData == null) return;
    Navigator.of(context).push(
      AppTransitions.slideRight(LinkedInCarouselScreen(data: resume.linkedInData!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resumeProvider = Provider.of<ResumeProvider>(context);

    // Filtrar currículos baseado na aba selecionada
    final filteredResumes = _tabController.index == 0
        ? resumeProvider.resumes.where(_isManualResume).toList()
        : resumeProvider.resumes.where(_isOptimizedResume).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.edit_note),
              text: 'Manual',
            ),
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'AI Optimized',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  AppTransitions.slideRight(const ResumeManualForm()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Manual'),
            )
          : null,
      body: SafeArea(
        child: resumeProvider.isLoading
            ? const Center(child: AppSpinner())
            : filteredResumes.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadResumes,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredResumes.length,
                      itemBuilder: (context, index) {
                        return _buildResumeCard(filteredResumes[index]);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isManualTab = _tabController.index == 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isManualTab
                    ? Colors.blue.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isManualTab ? Icons.edit_note : Icons.auto_awesome,
                size: 64,
                color: isManualTab ? Colors.blue : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isManualTab ? 'No Manual Resumes' : 'No AI Optimized Resumes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isManualTab
                  ? 'Create your first manual resume'
                  : 'Start optimizing your resume with AI',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeCard(Resume resume) {
    final isManual = _isManualResume(resume);
    final isLinkedIn = _isLinkedInResume(resume);
    const linkedInBlue = Color(0xFF0077B5);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        color: isManual
            ? Colors.blue.withValues(alpha: 0.05)
            : isLinkedIn
                ? const Color(0xFF0077B5).withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isManual
                ? Colors.blue.shade200
                : isLinkedIn
                    ? const Color(0xFF0077B5).withValues(alpha: 0.35)
                    : AppTheme.borderColor,
            width: isManual || isLinkedIn ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            final type = isLinkedIn ? 'linkedin' : (isManual ? 'manual' : 'ai_optimized');
            AnalyticsService.instance.logResumeDetailViewed(
              resumeType: type,
              score: resume.score,
            );
            if (isLinkedIn) {
              _openLinkedInCarousel(resume);
            } else if (isManual) {
              _editManualResume(resume);
            } else {
              _showResumeDetails(resume);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Linha de cabeçalho ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isManual
                            ? LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade400])
                            : isLinkedIn
                                ? const LinearGradient(colors: [Color(0xFF0077B5), Color(0xFF00A0DC)])
                                : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isManual ? Icons.person : (isLinkedIn ? Icons.badge : Icons.auto_awesome),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          if (isLinkedIn && resume.linkedInData != null) ...[
                            Text(
                              resume.linkedInData!.headline.isNotEmpty
                                  ? resume.linkedInData!.headline
                                  : 'LinkedIn Profile',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else if (!isManual && (resume.targetCompany != null || resume.targetRole != null)) ...[
                            if (resume.targetRole != null)
                              Text(
                                resume.targetRole!,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (resume.targetCompany != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.business_outlined, size: 13, color: AppTheme.primaryColor),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      resume.targetCompany!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else if (resume.nickname != null && resume.nickname!.isNotEmpty)
                            Text(
                              resume.nickname!,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          // Badge tipo
                          Row(
                            children: [
                              Icon(
                                isManual ? Icons.edit_note : (isLinkedIn ? Icons.badge : Icons.auto_awesome),
                                size: 14,
                                color: isManual ? Colors.blue.shade700 : (isLinkedIn ? linkedInBlue : AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isManual ? 'Manual Resume' : (isLinkedIn ? 'LinkedIn Optimization' : 'AI Optimized Resume'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isManual ? Colors.blue.shade700 : (isLinkedIn ? linkedInBlue : AppTheme.primaryColor),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Data
                          Text(
                            'Created ${DateFormat('MMM d, y').format(resume.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Botões direita — só para manuais
                    if (isManual)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            color: Colors.blue.shade700,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            tooltip: 'Edit Resume',
                            onPressed: () => _editManualResume(resume),
                          ),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            color: Colors.green.shade700,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            tooltip: 'Download PDF',
                            onPressed: () => _downloadPdf(resume),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: AppTheme.errorColor,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            tooltip: 'Delete Resume',
                            onPressed: () => _confirmDelete(resume),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Score + botões ───────────────────────────────────────────────────
                if (!isManual) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isLinkedIn && resume.linkedInData?.profileStrengthScore != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: linkedInBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${resume.linkedInData!.profileStrengthScore!.toStringAsFixed(0)}% strength',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: linkedInBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (!isLinkedIn && resume.score != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getScoreColor(resume.score!).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${resume.score!.toStringAsFixed(0)}% match',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getScoreColor(resume.score!),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      if (!isLinkedIn) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: AppTheme.primaryColor,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          tooltip: 'Edit Resume',
                          onPressed: () => _editOptimizedResume(resume),
                        ),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          color: Colors.green.shade700,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          tooltip: 'Download PDF',
                          onPressed: () => _downloadPdf(resume),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.errorColor,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        tooltip: 'Delete Resume',
                        onPressed: () => _confirmDelete(resume),
                      ),
                    ],
                  ),
                ],

                // ── Corpo ────────────────────────────────────────────
                const SizedBox(height: 12),
                if (isLinkedIn && resume.linkedInData != null)
                  _buildLinkedInCardBody(resume.linkedInData!)
                else if (isManual && resume.personal != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resume.personal!.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (resume.personal!.currentRole != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          resume.personal!.currentRole!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                      if (resume.experiences?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.work_outline,
                                size: 16, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${resume.experiences!.length} experience(s)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                else if (!isManual && resume.optimizedText != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resume.optimizedText!.length > 150
                            ? '${resume.optimizedText!.substring(0, 150)}...'
                            : resume.optimizedText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${resume.suggestions?.length ?? 0} suggestions',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textTertiary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (!isManual)
                  _buildOptimizedCardBody(resume),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedInCardBody(LinkedInOptimizedData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.about.isNotEmpty)
          Text(
            data.about.length > 150 ? '${data.about.substring(0, 150)}...' : data.about,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (data.experiences.isNotEmpty) ...[
              const Icon(Icons.work_outline, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text('${data.experiences.length} experience(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary)),
              const SizedBox(width: 12),
            ],
            if (data.skills.isNotEmpty) ...[
              const Icon(Icons.star_outline, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text('${data.skills.length} skills',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary)),
            ],
          ],
        ),
        if (data.suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text('${data.suggestions.length} suggestion(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOptimizedCardBody(Resume resume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score bar
        if (resume.score != null) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: resume.score! / 100,
                    minHeight: 6,
                    backgroundColor: AppTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(resume.score!)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${resume.score!.toStringAsFixed(0)}% match',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getScoreColor(resume.score!),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // Suggestions + missing
        Row(
          children: [
            if (resume.suggestions?.isNotEmpty == true) ...[
              const Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${resume.suggestions!.length} suggestions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
            ],
            if (resume.missingRequirements?.isNotEmpty == true) ...[
              const SizedBox(width: 12),
              const Icon(Icons.warning_amber_outlined, size: 14, color: AppTheme.warningColor),
              const SizedBox(width: 4),
              Text(
                '${resume.missingRequirements!.length} missing skills',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningColor,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  void _editManualResume(Resume resume) async {
    // Buscar detalhes completos do currículo antes de editar
    final resumeProvider = Provider.of<ResumeProvider>(context, listen: false);

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: AppSpinner(),
        ),
      );

      // Buscar detalhes completos passando o tipo
      final fullResume =
          await resumeProvider.getResumeById(resume.id, type: resume.type);

      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      if (fullResume != null && mounted) {
        Navigator.of(context).push(
          AppTransitions.slideRight(
            ResumeManualForm(
              initialResume: fullResume,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load resume details')),
          );
        }
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading resume: $e')),
        );
      }
    }
  }

  void _editOptimizedResume(Resume resume) async {
    // Buscar detalhes completos do currículo otimizado antes de editar
    final resumeProvider = Provider.of<ResumeProvider>(context, listen: false);

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: AppSpinner(),
        ),
      );

      // Buscar detalhes completos passando o tipo
      final fullResume =
          await resumeProvider.getResumeById(resume.id, type: resume.type);

      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      if (fullResume != null && mounted) {
        
        // Verificar se tem dados estruturados
        if (fullResume.personal != null) {
          // Tem dados estruturados, pode editar
          Navigator.of(context).push(
            AppTransitions.slideRight(
              ResumeManualForm(
                initialResume: fullResume,
              ),
            ),
          );
        } else {
          // Não tem dados estruturados
          
          final shouldCreateNew = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('No Structured Data')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This optimized resume doesn\'t have structured data yet.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 To enable editing:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'The backend needs to include personal, experiences, education, and projects when returning optimized resumes.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Would you like to create a new manual resume instead?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Create New Manual'),
                ),
              ],
            ),
          );

          if (shouldCreateNew == true && mounted) {
            Navigator.of(context).push(
              AppTransitions.slideRight(const ResumeManualForm()),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load resume details')),
          );
        }
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) Navigator.of(context).pop();

      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading resume: $e')),
        );
      }
    }
  }

  void _showResumeDetails(Resume resume) {
    final isManual = _isManualResume(resume);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                resume.nickname ??
                                    (isManual
                                        ? 'Manual Resume'
                                        : 'Resume Details'),
                                style: Theme.of(context).textTheme.displaySmall,
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (isManual)
                          _buildManualResumeDetails(resume)
                        else
                          _buildOptimizedResumeDetails(resume),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildManualResumeDetails(Resume resume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resume.personal != null) ...[
          _buildSection(
            'Personal Information',
            [
              _buildInfoRow('Name', resume.personal!.fullName),
              _buildInfoRow('Email', resume.personal!.email),
              if (resume.personal!.phone != null)
                _buildInfoRow('Phone', resume.personal!.phone!),
              if (resume.personal!.currentRole != null)
                _buildInfoRow('Current Role', resume.personal!.currentRole!),
              if (resume.personal!.city != null ||
                  resume.personal!.state != null ||
                  resume.personal!.country != null)
                _buildInfoRow(
                    'Location',
                    [
                      resume.personal!.city,
                      resume.personal!.state,
                      resume.personal!.country
                    ].where((e) => e != null).join(', ')),
            ],
          ),
          if (resume.personal!.summary != null) ...[
            const SizedBox(height: 24),
            Text('Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                resume.personal!.summary!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
        if (resume.experiences?.isNotEmpty == true) ...[
          const SizedBox(height: 24),
          Text('Work Experience',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...resume.experiences!.map((exp) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.role,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.company,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate ?? "N/A"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (exp.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        exp.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              )),
        ],
        if (resume.education?.isNotEmpty == true) ...[
          const SizedBox(height: 24),
          Text('Education', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...resume.education!.map((edu) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu.degree,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      edu.institution,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${edu.startDate} - ${edu.isCurrent ? "Present" : edu.endDate ?? "N/A"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              )),
        ],
        if (resume.projects?.isNotEmpty == true) ...[
          const SizedBox(height: 24),
          Text('Projects', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...resume.projects!.map((proj) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proj.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (proj.url != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        proj.url!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      proj.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildOptimizedResumeDetails(Resume resume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Empresa + Cargo
        if (resume.targetCompany != null || resume.targetRole != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_center_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (resume.targetRole != null)
                        Text(
                          resume.targetRole!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (resume.targetCompany != null)
                        Text(
                          resume.targetCompany!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Match Score
        if (resume.score != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How well you match the job',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${resume.score!.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Suggestions
        if (resume.suggestions?.isNotEmpty == true) ...[
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Text(
                'Improvement Suggestions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...resume.suggestions!.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(12),
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
                      suggestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Missing Requirements
        if (resume.missingRequirements?.isNotEmpty == true) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined, size: 20, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Text(
                'Missing Skills / Requirements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resume.missingRequirements!.map((req) => Chip(
              label: Text(req, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppTheme.warningColor.withValues(alpha: 0.1),
              side: BorderSide(color: AppTheme.warningColor.withValues(alpha: 0.4)),
            )).toList(),
          ),
        ],

        // Salary Estimate
        if (resume.salaryEstimate != null && resume.salaryEstimate!.found) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 20, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Text(
                'Salary Estimate',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSalaryEstimateCard(resume.salaryEstimate!),
        ],

        // Se não tem nenhum dado de otimização, mostrar mensagem
        if (resume.score == null && 
            (resume.optimizedText == null || resume.optimizedText!.isEmpty) && 
            (resume.suggestions == null || resume.suggestions!.isEmpty)) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No optimization data available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'This resume hasn\'t been optimized yet or the optimization data is not available.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSalaryEstimateCard(SalaryEstimate salary) {
    final currency = salary.currency ?? '';
    String _fmt(double? v) => v == null ? '—' : NumberFormat.compact(locale: 'en_US').format(v);
    final rangeText = (salary.minSalary != null && salary.maxSalary != null)
        ? '$currency ${_fmt(salary.minSalary)} – ${_fmt(salary.maxSalary)}'
        : (salary.midpoint != null ? '$currency ${_fmt(salary.midpoint)}' : '—');
    final period = salary.period != null ? ' / ${salary.period}' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$rangeText$period',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                  ),
                  if (salary.midpoint != null && salary.minSalary != null)
                    Text(
                      'Midpoint: $currency ${_fmt(salary.midpoint)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                ],
              ),
            ],
          ),
          // Tags row
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (salary.location != null)
                _buildSalaryChip(Icons.location_on_outlined, salary.location!),
              if (salary.seniority != null)
                _buildSalaryChip(Icons.work_outline, _capitalize(salary.seniority!)),
              if (salary.currency != null)
                _buildSalaryChip(Icons.currency_exchange, salary.currency!),
            ],
          ),
          // Notes
          if (salary.notes != null) ...[
            const SizedBox(height: 12),
            Text(
              salary.notes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
          // Disclaimer
          if (salary.disclaimer != null) ...[
            const SizedBox(height: 8),
            Text(
              salary.disclaimer!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.successColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(Resume resume) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: AppSpinner(),
        ),
      );

      final pdfService = PdfService();
      
      // Fechar loading
      if (mounted) Navigator.of(context).pop();
      
      // Abrir preview/compartilhar PDF
      await pdfService.previewPdf(resume);

      final type = resume.type == 'linkedin'
          ? 'linkedin'
          : (resume.type == 'manual' ? 'manual' : 'ai_optimized');
      AnalyticsService.instance.logResumePdfDownloaded(resumeType: type);
      
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Resume resume) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resume'),
        content: Text(
          'Are you sure you want to delete "${resume.nickname ?? 'this resume'}"? This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final type = resume.type == 'linkedin'
          ? 'linkedin'
          : (resume.type == 'manual' ? 'manual' : 'ai_optimized');
      AnalyticsService.instance.logResumeDeleted(resumeType: type);
      await _deleteResume(resume.id);
    }
  }

  Future<void> _deleteResume(String resumeId) async {
    final resumeProvider = Provider.of<ResumeProvider>(context, listen: false);


    try {
      await resumeProvider.deleteResume(resumeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete resume: $e')),
        );
      }
    }
  }
}
