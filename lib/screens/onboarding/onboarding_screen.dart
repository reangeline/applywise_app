import 'package:flutter/material.dart';
import 'dart:math';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../services/analytics_service.dart';
import '../../services/storage_service.dart';
import 'resume_entry_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Log the first onboarding step on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logOnboardingStepViewed(
        stepIndex: 0,
        stepTitle: _pages[0].title,
      );
    });
  }

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      imagePath: 'assets/images/onbording/onbording_1.png',
      title: 'Most resumes never reach a recruiter',
      description:
          'Applicant Tracking Systems automatically reject resumes before a human sees them.',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onbording/onbording_2.png',
      title: 'Great experience. No interviews.',
      description: 'Design, photos, and generic resumes often fail automated screening.',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onbording/onbording_3.png',
      title: 'We fix your resume for hiring systems',
      description:
          'We adapt your resume to each job description using ATS-friendly structure and keywords.',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onbording/onbording_4.png',
      title: 'Land more interviews',
      description:
          'Stand out from the competition with optimized applications',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  AnalyticsService.instance.logOnboardingStepViewed(
                    stepIndex: index,
                    stepTitle: _pages[index].title,
                  );
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildIndicator(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleNextOrGetStarted,
                      child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () {
                        AnalyticsService.instance.logOnboardingSkipped(
                          atStep: _currentPage,
                        );
                        _navigateToLogin();
                      },
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Larger image at top (responsive height)
                  Builder(
                    builder: (ctx) {
                      final maxHeight = MediaQuery.of(ctx).size.height * 0.45;
                      final imageHeight = min(360.0, maxHeight);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          page.imagePath,
                          width: double.infinity,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Center(
                            child: Icon(Icons.broken_image, size: 64, color: Theme.of(context).disabledColor),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 20,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicator() {
    return Semantics(
      label: 'Page ${_currentPage + 1} of ${_pages.length}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pages.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToLogin() async {
    await StorageService().setFirstLaunchDone();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      AppTransitions.fadeSlide(const ResumeEntryScreen()),
    );
  }

  void _handleNextOrGetStarted() {
    if (_currentPage == _pages.length - 1) {
      AnalyticsService.instance.logOnboardingCompleted();
      _navigateToLogin();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String imagePath;
  final String title;
  final String description;

  OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
