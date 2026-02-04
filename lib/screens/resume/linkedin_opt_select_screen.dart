import 'package:flutter/material.dart';
import 'linkedin_carousel_screen.dart';

class LinkedInOptSelectScreen extends StatefulWidget {
  const LinkedInOptSelectScreen({super.key});

  @override
  State<LinkedInOptSelectScreen> createState() => _LinkedInOptSelectScreenState();
}

class _LinkedInOptSelectScreenState extends State<LinkedInOptSelectScreen> {
  int _selected = 0;

  final List<String> _mockResumes = [
    'Resume A — Product Manager with 7 years in SaaS, PM & growth',
    'Resume B — Senior Software Engineer, Flutter & Node.js, 6+ years',
    'Resume C — Data Analyst focused on ML pipelines and insights',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Resume')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _mockResumes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Theme.of(context).cardColor,
                    title: Text(_mockResumes[idx]),
                    leading: Radio<int>(
                      value: idx,
                      groupValue: _selected,
                      onChanged: (v) => setState(() => _selected = v ?? 0),
                    ),
                    onTap: () => setState(() => _selected = idx),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final selectedResume = _mockResumes[_selected];
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LinkedInCarouselScreen(resumeText: selectedResume),
                    ),
                  );
                },
                child: const Text('Optimize for LinkedIn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
