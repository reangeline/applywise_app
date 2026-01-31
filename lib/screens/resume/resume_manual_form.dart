import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/resume_provider.dart';
import '../../models/resume.dart';

class ResumeManualForm extends StatefulWidget {
  const ResumeManualForm({super.key});

  @override
  State<ResumeManualForm> createState() => _ResumeManualFormState();
}

class _ResumeManualFormState extends State<ResumeManualForm> {
  int _currentStep = 0;

  final Map<String, String> _personal = {};
  final List<Map<String, String>> _experiences = [];
  final List<Map<String, String>> _education = [];
  final List<Map<String, String>> _projects = [];

  void _next() => setState(() { if (_currentStep < 4) _currentStep++; });
  void _back() => setState(() { if (_currentStep > 0) _currentStep--; });

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Resume nickname (e.g. "Product Manager - Salesforce")'),
          onChanged: (v) => _personal['nickname'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Full name'),
          onChanged: (v) => _personal['name'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (v) => _personal['email'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Phone (optional)'),
          keyboardType: TextInputType.phone,
          onChanged: (v) => _personal['phone'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Current role / Title (e.g. Software Engineer)'),
          onChanged: (v) => _personal['role'] = v,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Country (optional)'), onChanged: (v) => _personal['country'] = v)),
            const SizedBox(width: 12),
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'State (optional)'), onChanged: (v) => _personal['state'] = v)),
            const SizedBox(width: 12),
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'City (optional)'), onChanged: (v) => _personal['city'] = v)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'LinkedIn (optional)'),
          onChanged: (v) => _personal['linkedin'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Personal website (optional)'),
          onChanged: (v) => _personal['website'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'GitHub (optional)'),
          onChanged: (v) => _personal['github'] = v,
        ),
      ],
    );
  }

  Widget _summaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Career summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Write a short summary about your career, highlights and goals.'),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            hintText: 'E.g. Senior software engineer with 8 years of experience...',
            border: OutlineInputBorder(),
          ),
          minLines: 4,
          maxLines: 8,
          onChanged: (v) => _personal['summary'] = v,
        ),
      ],
    );
  }

  Widget _experienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Work experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => _experiences.add({'id': const Uuid().v4(), 'role': '', 'company': '', 'start': '', 'end': '', 'desc': ''})),
          icon: const Icon(Icons.add),
          label: const Text('Add experience'),
        ),
        const SizedBox(height: 12),
        ..._experiences.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Card(
            key: ValueKey(item['id']),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Experience ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _experiences.removeAt(i))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(decoration: const InputDecoration(labelText: 'Role'), onChanged: (v) => item['role'] = v),
                  const SizedBox(height: 10),
                  TextField(decoration: const InputDecoration(labelText: 'Company'), onChanged: (v) => item['company'] = v),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Start date',
                          suffixIcon: const Icon(Icons.calendar_month),
                        ),
                        controller: TextEditingController(text: item['start'] ?? ''),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(item['start'] ?? '') ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            item['start'] = DateFormat('yyyy-MM-dd').format(picked);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: item['current'] == 'true'
                          ? InputDecorator(
                              decoration: const InputDecoration(labelText: 'End date'),
                              child: const Text('Present'),
                            )
                          : TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End date',
                                suffixIcon: const Icon(Icons.calendar_month),
                              ),
                              controller: TextEditingController(text: item['end'] ?? ''),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(item['end'] ?? '') ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  item['end'] = DateFormat('yyyy-MM-dd').format(picked);
                                  setState(() {});
                                }
                              },
                            ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: item['current'] == 'true',
                        onChanged: (v) => setState(() => item['current'] = v == true ? 'true' : 'false'),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(child: Text('I currently work here')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    minLines: 4,
                    maxLines: 8,
                    onChanged: (v) => item['desc'] = v,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _educationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Education & certifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => _education.add({'id': const Uuid().v4(), 'school': '', 'degree': '', 'start': '', 'end': '', 'current': 'false'})),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
        const SizedBox(height: 12),
        ..._education.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Card(
            key: ValueKey(item['id']),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Item ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _education.removeAt(i))),
                ]),
                const SizedBox(height: 8),
                TextField(decoration: const InputDecoration(labelText: 'Institution / Course'), onChanged: (v) => item['school'] = v),
                const SizedBox(height: 10),
                TextField(decoration: const InputDecoration(labelText: 'Degree / Certificate'), onChanged: (v) => item['degree'] = v),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Start date',
                        suffixIcon: const Icon(Icons.calendar_month),
                      ),
                      controller: TextEditingController(text: item['start'] ?? ''),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(item['start'] ?? '') ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          item['start'] = DateFormat('yyyy-MM-dd').format(picked);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: item['current'] == 'true'
                        ? InputDecorator(
                            decoration: const InputDecoration(labelText: 'End date'),
                            child: const Text('Present'),
                          )
                        : TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'End date',
                              suffixIcon: const Icon(Icons.calendar_month),
                            ),
                            controller: TextEditingController(text: item['end'] ?? ''),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(item['end'] ?? '') ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                item['end'] = DateFormat('yyyy-MM-dd').format(picked);
                                setState(() {});
                              }
                            },
                          ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: item['current'] == 'true',
                      onChanged: (v) => setState(() => item['current'] = v == true ? 'true' : 'false'),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(child: Text('I currently study here')),
                  ],
                ),
              ]),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _projectsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Projects (optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () => setState(() => _projects.add({'name': '', 'url': '', 'desc': ''})), icon: const Icon(Icons.add), label: const Text('Add project')),
        const SizedBox(height: 12),
        ..._projects.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Project ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _projects.removeAt(i))),
                ]),
                const SizedBox(height: 8),
                TextField(decoration: const InputDecoration(labelText: 'Project name'), onChanged: (v) => item['name'] = v),
                const SizedBox(height: 10),
                TextField(decoration: const InputDecoration(labelText: 'URL (optional)'), onChanged: (v) => item['url'] = v),
                const SizedBox(height: 10),
                TextField(decoration: const InputDecoration(labelText: 'Description'), minLines: 3, maxLines: 6, onChanged: (v) => item['desc'] = v),
              ]),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _finish() {
    final provider = Provider.of<ResumeProvider>(context, listen: false);

    // Build a simple Resume from inputs (mock/placeholder)
    final uuid = const Uuid().v4();
    final combined = StringBuffer();
    combined.writeln(_personal['nickname'] ?? '');
    combined.writeln(_personal['name'] ?? '');
    combined.writeln(_personal['role'] ?? '');
    combined.writeln(_personal['email'] ?? '');
    combined.writeln(_personal['country'] ?? '');
    combined.writeln(_personal['state'] ?? '');
    combined.writeln(_personal['city'] ?? '');
    combined.writeln('Summary: ${_personal['summary'] ?? ''}');
    for (final e in _experiences) {
      combined.writeln('${e['role'] ?? ''} at ${e['company'] ?? ''}');
      combined.writeln('${e['start'] ?? ''} - ${e['end'] ?? ''}');
      combined.writeln('${e['desc'] ?? ''}');
    }

    final resume = Resume(
      id: uuid,
      optimizedText: combined.toString(),
      suggestions: [],
      score: 0,
      createdAt: DateTime.now(),
    );

    provider.addLocalResume(resume);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resume saved')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Resume')), 
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Step ${_currentStep + 1} of 5', style: const TextStyle(fontWeight: FontWeight.w600)), TextButton(onPressed: () { /* could skip */ }, child: const Text('Skip'))]),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _currentStep == 0 ? _personalStep() : _currentStep == 1 ? _summaryStep() : _currentStep == 2 ? _experienceStep() : _currentStep == 3 ? _educationStep() : _projectsStep()))),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: OutlinedButton(onPressed: _back, child: const Text('Back'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _currentStep == 4 ? _finish : _next, child: Text(_currentStep == 4 ? 'Finish' : 'Next')))]),
          ]),
        ),
      ),
    );
  }
}
