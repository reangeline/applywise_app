import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/resume.dart';
import '../../config/theme.dart';

class LinkedInCarouselScreen extends StatefulWidget {
  final LinkedInOptimizedData data;
  const LinkedInCarouselScreen({super.key, required this.data});

  @override
  State<LinkedInCarouselScreen> createState() => _LinkedInCarouselScreenState();
}

class _LinkedInCarouselScreenState extends State<LinkedInCarouselScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  LinkedInOptimizedData get data => widget.data;

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  List<_LinkedInSlide> _buildSlides() {
    final slides = <_LinkedInSlide>[];

    // 1. Headline
    slides.add(_LinkedInSlide(
      label: 'Headline',
      icon: Icons.title,
      child: _textContent(data.headline, maxChars: 220),
      copyText: data.headline,
    ));

    // 2. About
    slides.add(_LinkedInSlide(
      label: 'About',
      icon: Icons.person_outline,
      child: _textContent(data.about, maxChars: 2600),
      copyText: data.about,
    ));

    // 3. Experiences (one slide each)
    for (var i = 0; i < data.experiences.length; i++) {
      final exp = data.experiences[i];
      final period = exp.isCurrent
          ? '${exp.startDate} – Present'
          : '${exp.startDate} – ${exp.endDate ?? ''}';
      final copyText = '${exp.role} at ${exp.company}\n$period\n\n${exp.description}';
      slides.add(_LinkedInSlide(
        label: 'Experience ${i + 1}',
        icon: Icons.work_outline,
        copyText: copyText,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exp.role,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              exp.company,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              period,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  exp.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    // 4. Skills
    if (data.skills.isNotEmpty) {
      slides.add(_LinkedInSlide(
        label: 'Skills',
        icon: Icons.star_outline,
        copyText: data.skills.join(', '),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.skills.map((s) => Chip(
              label: Text(s, style: const TextStyle(fontSize: 13)),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            )).toList(),
          ),
        ),
      ));
    }

    // 5. Languages
    if (data.languages.isNotEmpty) {
      final langText = data.languages.map((l) => '${l.name} – ${l.level}').join('\n');
      slides.add(_LinkedInSlide(
        label: 'Languages',
        icon: Icons.language,
        copyText: langText,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.languages.map((lang) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    Text(lang.level,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            )),
                  ],
                ),
              ],
            ),
          )).toList(),
        ),
      ));
    }

    // 6. Profile Strength + Suggestions
    if (data.profileStrengthScore != null || data.suggestions.isNotEmpty) {
      slides.add(_LinkedInSlide(
        label: 'Profile Score',
        icon: Icons.insights,
        copyText: data.suggestions.map((s) => '• $s').join('\n'),
        child: _buildScoreAndSuggestions(),
      ));
    }

    return slides;
  }

  Widget _textContent(String text, {int? maxChars}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (maxChars != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${text.length} / $maxChars characters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: text.length > maxChars
                        ? AppTheme.errorColor
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreAndSuggestions() {
    final score = data.profileStrengthScore;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (score != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Strength',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        'Based on LinkedIn best practices',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
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
                      '${score.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (data.suggestions.isNotEmpty) ...[
            Text('Tips to Improve',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            ...data.suggestions.asMap().entries.map((e) => Container(
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
                          color: AppTheme.warningColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn Optimization'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: slides.isEmpty ? 0 : (_currentPage + 1) / slides.length,
            backgroundColor: AppTheme.borderColor,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, idx) {
                final slide = slides[idx];
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildSlideCard(slide, idx, slides.length),
                );
              },
            ),
          ),
          _buildNavBar(slides.length),
        ],
      ),
    );
  }

  Widget _buildSlideCard(_LinkedInSlide slide, int idx, int total) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(slide.icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(slide.label,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Text('${idx + 1} / $total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      )),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 8),
          // Content
          Expanded(child: slide.child),
          const SizedBox(height: 12),
          // Copy button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _copy(slide.copyText),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              if (_currentPage > 0) {
                _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(_currentPage == 0 ? 'Back' : 'Previous'),
          ),
          const Spacer(),
          // Dot indicators
          Row(
            children: List.generate(
              total,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < total - 1) {
                _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(_currentPage < total - 1 ? 'Next' : 'Done'),
          ),
        ],
      ),
    );
  }
}

class _LinkedInSlide {
  final String label;
  final IconData icon;
  final Widget child;
  final String copyText;

  const _LinkedInSlide({
    required this.label,
    required this.icon,
    required this.child,
    required this.copyText,
  });
}

