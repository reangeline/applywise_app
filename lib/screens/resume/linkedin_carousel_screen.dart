import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkedInCarouselScreen extends StatefulWidget {
  final String resumeText;
  const LinkedInCarouselScreen({super.key, required this.resumeText});

  @override
  State<LinkedInCarouselScreen> createState() => _LinkedInCarouselScreenState();
}

class _LinkedInCarouselScreenState extends State<LinkedInCarouselScreen> {
  final PageController _controller = PageController();

  String _generateHeadline(String resume) {
    // Mocked headline generation based on the selected resume text.
    if (resume.contains('Product Manager')) {
      return 'Product Manager • 7+ years in SaaS • Product Strategy & Growth';
    }
    if (resume.contains('Software Engineer') || resume.contains('Flutter')) {
      return 'Senior Software Engineer • Full‑stack • Flutter & Node.js • 6+ yrs';
    }
    if (resume.contains('Data Analyst')) {
      return 'Data Analyst • ML pipelines & insights • SQL, Python';
    }
    return 'Professional with relevant experience — concise skill summary';
  }

  String _generateSummary(String resume) {
    return 'Summary (mocked): ${resume.split(' — ').first} with proven results in relevant domains. Expand with metric-driven achievements.';
  }

  String _generateExperience(String resume) {
    return 'Experience (mocked): Key roles and achievements derived from the selected resume. Convert bullets to impact statements.';
  }

  @override
  Widget build(BuildContext context) {
    final headline = _generateHeadline(widget.resumeText);
    final summary = _generateSummary(widget.resumeText);
    final experience = _generateExperience(widget.resumeText);

    final slides = <Widget>[
      _buildSlide(
        title: 'Headline',
        content: headline,
        onCopy: () => Clipboard.setData(ClipboardData(text: headline)),
      ),
      _buildSlide(
        title: 'Summary',
        content: summary,
        onCopy: () => Clipboard.setData(ClipboardData(text: summary)),
      ),
      _buildSlide(
        title: 'Experience',
        content: experience,
        onCopy: () => Clipboard.setData(ClipboardData(text: experience)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('LinkedIn Optimization')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              itemBuilder: (context, idx) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: slides[idx],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    if (_controller.page != null && _controller.page! > 0) {
                      _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Back'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final page = (_controller.page ?? 0).round();
                    if (page < slides.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlide({required String title, required String content, required VoidCallback onCopy}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(content, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  onCopy();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                },
                child: const Text('Copy'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  // Edit action can be implemented later
                },
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
