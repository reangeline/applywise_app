import 'package:flutter/material.dart';
import '../../config/theme.dart';

class OptimizeInfoScreen extends StatefulWidget {
  const OptimizeInfoScreen({super.key});

  @override
  State<OptimizeInfoScreen> createState() => _OptimizeInfoScreenState();
}

class _OptimizeInfoScreenState extends State<OptimizeInfoScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<Map<String, String>> slides = [
    {
      'header': 'How Resume Optimization for ATS Works',
      'body': 'Applicant Tracking Systems (ATS) scan your resume to check if you match the job description.',
      'image': 'assets/images/explain_ats/image_1.png'
    },
    {
      'header': 'ATS Extract Keywords from the Job Description',
      'body': 'ATS extract important keywords like skills, experiences, and certifications from the job posting.',
      'image': 'assets/images/explain_ats/image_2.png'
    },
    {
      'header': 'Your Resume Is Analyzed & Scored Based on Match',
      'body': 'ATS compare these keywords with your resume and give you a score based on how well you match the job description.',
      'image': 'assets/images/explain_ats/image_3.png'
    },
    {
      'header': 'Many Resumes Fail the ATS Formatting Test',
      'body': 'Photos, columns, and graphics confuse the ATS and cause it to reject the resume.',
      'image': 'assets/images/explain_ats/image_4.png'
    },
    {
      'header': 'Why ATS-Optimized Resumes Get You Noticed',
      'body': 'Most resumes never reach a human recruiter because they get filtered out by Applicant Tracking Systems (ATS). In the U.S., up to 75% of resumes are rejected before they’re ever seen by a person if they aren’t structured in a simple, keyword-rich format that ATS can read.',
      'image': 'assets/images/explain_ats/image_5.png'
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('How Optimization Works'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 450),
                            opacity: _page == i ? 1.0 : 0.6,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Header (larger) - placed above image, minimal gap
                                Text(
                                  s['header'] ?? '',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),

                                // Smaller fixed-height image (restored) placed below header
                                if ((s['image'] ?? '').isNotEmpty) ...[
                                  SizedBox(
                                    height: 220,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        s['image'] ?? '',
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 80,
                                            color: Theme.of(context).disabledColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // Body (larger font)
                                Text(
                                  s['body'] ?? '',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, height: 1.3),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primaryColor : AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () {
                        _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_page < slides.length - 1) {
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(_page < slides.length - 1 ? 'Next' : 'Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconFor(String key) {
    IconData icon;
    switch (key) {
      case 'search':
        icon = Icons.search;
        break;
      case 'compare':
        icon = Icons.compare_arrows;
        break;
      default:
        icon = Icons.auto_awesome;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(80),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Icon(icon, size: 48, color: AppTheme.primaryColor),
    );
  }
}
