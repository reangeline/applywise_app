import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../providers/resume_provider.dart';
import '../../models/resume.dart';

class ResumeManualForm extends StatefulWidget {
  final Resume? initialResume;

  const ResumeManualForm({super.key, this.initialResume});

  @override
  State<ResumeManualForm> createState() => _ResumeManualFormState();
}

class _ResumeManualFormState extends State<ResumeManualForm> {
  int _currentStep = 0;

  final Map<String, String> _personal = {};
  final List<Map<String, String>> _experiences = [];
  final List<Map<String, String>> _education = [];
  final List<Map<String, String>> _projects = [];
  final List<Map<String, String>> _languages = [];

  @override
  void initState() {
    super.initState();

    // If an initial resume is provided, populate local form state
    final r = widget.initialResume;
    if (r != null && r.personal != null) {
      _personal['nickname'] = r.nickname ?? '';
      _personal['name'] = r.personal!.fullName;
      _personal['email'] = r.personal!.email;
      if (r.personal!.phone != null) _personal['phone'] = r.personal!.phone!;
      if (r.personal!.currentRole != null) _personal['role'] = r.personal!.currentRole!;
      if (r.personal!.country != null) _personal['country'] = r.personal!.country!;
      if (r.personal!.state != null) _personal['state'] = r.personal!.state!;
      if (r.personal!.city != null) _personal['city'] = r.personal!.city!;
      if (r.personal!.linkedinUrl != null) _personal['linkedin'] = r.personal!.linkedinUrl!;
      if (r.personal!.websiteUrl != null) _personal['website'] = r.personal!.websiteUrl!;
      if (r.personal!.githubUrl != null) _personal['github'] = r.personal!.githubUrl!;
      if (r.personal!.summary != null) _personal['summary'] = r.personal!.summary!;
    }

    if (r != null && r.experiences != null) {
      for (final exp in r.experiences!) {
        _experiences.add({
          'id': const Uuid().v4(),
          'role': exp.role,
          'company': exp.company,
          'start': exp.startDate,
          'end': exp.endDate ?? '',
          'current': exp.isCurrent ? 'true' : 'false',
          'desc': exp.description,
        });
      }
    }

    if (r != null && r.education != null) {
      for (final edu in r.education!) {
        _education.add({
          'id': const Uuid().v4(),
          'school': edu.institution,
          'degree': edu.degree,
          'start': edu.startDate,
          'end': edu.endDate ?? '',
          'current': edu.isCurrent ? 'true' : 'false',
        });
      }
    }

    if (r != null && r.projects != null) {
      for (final p in r.projects!) {
        _projects.add({
          'name': p.name,
          'url': p.url ?? '',
          'desc': p.description,
        });
      }
    }

    if (r != null && r.languages != null) {
      for (final lang in r.languages!) {
        _languages.add({
          'id': const Uuid().v4(),
          'language': lang.language,
          'proficiency': lang.proficiency,
        });
      }
    }
  }

  void _next() => setState(() { if (_currentStep < 5) _currentStep++; });
  void _back() => setState(() { if (_currentStep > 0) _currentStep--; });

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Resume nickname (e.g. "Product Manager - Salesforce")'),
          controller: TextEditingController(text: _personal['nickname'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['nickname'] ?? '').length),
          onChanged: (v) => _personal['nickname'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Full name'),
          controller: TextEditingController(text: _personal['name'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['name'] ?? '').length),
          onChanged: (v) => _personal['name'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Email'),
          controller: TextEditingController(text: _personal['email'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['email'] ?? '').length),
          onChanged: (v) => _personal['email'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Phone (optional)'),
          keyboardType: TextInputType.phone,
          controller: TextEditingController(text: _personal['phone'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['phone'] ?? '').length),
          onChanged: (v) => _personal['phone'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Current role / Title (e.g. Software Engineer)'),
          controller: TextEditingController(text: _personal['role'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['role'] ?? '').length),
          onChanged: (v) => _personal['role'] = v,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Country (optional)'),
                controller: TextEditingController(text: _personal['country'] ?? '')
                  ..selection = TextSelection.collapsed(offset: (_personal['country'] ?? '').length),
                onChanged: (v) => _personal['country'] = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'State (optional)'),
                controller: TextEditingController(text: _personal['state'] ?? '')
                  ..selection = TextSelection.collapsed(offset: (_personal['state'] ?? '').length),
                onChanged: (v) => _personal['state'] = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'City (optional)'),
                controller: TextEditingController(text: _personal['city'] ?? '')
                  ..selection = TextSelection.collapsed(offset: (_personal['city'] ?? '').length),
                onChanged: (v) => _personal['city'] = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'LinkedIn (optional)'),
          controller: TextEditingController(text: _personal['linkedin'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['linkedin'] ?? '').length),
          onChanged: (v) => _personal['linkedin'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Personal website (optional)'),
          controller: TextEditingController(text: _personal['website'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['website'] ?? '').length),
          onChanged: (v) => _personal['website'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'GitHub (optional)'),
          controller: TextEditingController(text: _personal['github'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['github'] ?? '').length),
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
          controller: TextEditingController(text: _personal['summary'] ?? '')
            ..selection = TextSelection.collapsed(offset: (_personal['summary'] ?? '').length),
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
                  TextField(
                    decoration: const InputDecoration(labelText: 'Role'),
                    controller: TextEditingController(text: item['role'] ?? '')
                      ..selection = TextSelection.collapsed(offset: (item['role'] ?? '').length),
                    onChanged: (v) => item['role'] = v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Company'),
                    controller: TextEditingController(text: item['company'] ?? '')
                      ..selection = TextSelection.collapsed(offset: (item['company'] ?? '').length),
                    onChanged: (v) => item['company'] = v,
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Start date',
                          suffixIcon: Icon(Icons.calendar_month),
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
                          ? const InputDecorator(
                              decoration: InputDecoration(labelText: 'End date'),
                              child: Text('Present'),
                            )
                          : TextField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'End date',
                                suffixIcon: Icon(Icons.calendar_month),
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
                    controller: TextEditingController(text: item['desc'] ?? '')
                      ..selection = TextSelection.collapsed(offset: (item['desc'] ?? '').length),
                    onChanged: (v) => item['desc'] = v,
                  ),
                ],
              ),
            ),
          );
        }),
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
                TextField(
                  decoration: const InputDecoration(labelText: 'Institution / Course'),
                  controller: TextEditingController(text: item['school'] ?? '')
                    ..selection = TextSelection.collapsed(offset: (item['school'] ?? '').length),
                  onChanged: (v) => item['school'] = v,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Degree / Certificate'),
                  controller: TextEditingController(text: item['degree'] ?? '')
                    ..selection = TextSelection.collapsed(offset: (item['degree'] ?? '').length),
                  onChanged: (v) => item['degree'] = v,
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start date',
                        suffixIcon: Icon(Icons.calendar_month),
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
                        ? const InputDecorator(
                            decoration: InputDecoration(labelText: 'End date'),
                            child: Text('Present'),
                          )
                        : TextField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'End date',
                              suffixIcon: Icon(Icons.calendar_month),
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
        }),
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
                TextField(
                  decoration: const InputDecoration(labelText: 'Project name'),
                  controller: TextEditingController(text: item['name'] ?? '')
                    ..selection = TextSelection.collapsed(offset: (item['name'] ?? '').length),
                  onChanged: (v) => item['name'] = v,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'URL (optional)'),
                  controller: TextEditingController(text: item['url'] ?? '')
                    ..selection = TextSelection.collapsed(offset: (item['url'] ?? '').length),
                  onChanged: (v) => item['url'] = v,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 3,
                  maxLines: 6,
                  controller: TextEditingController(text: item['desc'] ?? '')
                    ..selection = TextSelection.collapsed(offset: (item['desc'] ?? '').length),
                  onChanged: (v) => item['desc'] = v,
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _languagesStep() {
    const proficiencyLevels = [
      'Basic',
      'Conversational',
      'Professional',
      'Fluent',
      'Native',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Languages (optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => _languages.add({'language': '', 'proficiency': 'Professional'})),
          icon: const Icon(Icons.add),
          label: const Text('Add language'),
        ),
        const SizedBox(height: 12),
        ..._languages.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Language ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _languages.removeAt(i)),
                  ),
                ]),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Language (e.g., English, Spanish)'),
                  controller: TextEditingController(text: item['language'] ?? '')
                    ..selection = TextSelection.collapsed(offset: (item['language'] ?? '').length),
                  onChanged: (v) => item['language'] = v,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Proficiency'),
                  value: item['proficiency'] ?? 'Professional',
                  items: proficiencyLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => item['proficiency'] = v ?? 'Professional'),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }

  void _finish() async {
    final provider = Provider.of<ResumeProvider>(context, listen: false);
    
    // Validações básicas
    if (_personal['name']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome completo é obrigatório')),
      );
      return;
    }
    
    if (_personal['email']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email é obrigatório')),
      );
      return;
    }
    
    final initialResume = widget.initialResume;
    
    // Construir payload estruturado conforme backend
    // Usar o tipo original do currículo ou 'manual' para novos
    final payload = {
      'type': initialResume?.type ?? 'manual',
      'nickname': _personal['nickname']?.isNotEmpty == true 
          ? _personal['nickname'] 
          : 'Resume - ${DateTime.now().toString().substring(0, 10)}',
      'personal': {
        'full_name': _personal['name'] ?? '',
        'email': _personal['email'] ?? '',
        'phone': _personal['phone'],
        'current_role': _personal['role'],
        'country': _personal['country'],
        'state': _personal['state'],
        'city': _personal['city'],
        'linkedin_url': _personal['linkedin'],
        'website_url': _personal['website'],
        'github_url': _personal['github'],
        'summary': _personal['summary'],
      },
      'experiences': _experiences.map((e) => {
        'role': e['role'] ?? '',
        'company': e['company'] ?? '',
        'start_date': e['start'] ?? '',
        'end_date': e['current'] == 'true' ? null : e['end'],
        'is_current': e['current'] == 'true',
        'description': e['desc'] ?? '',
      }).toList(),
      'education': _education.map((e) => {
        'institution': e['school'] ?? '',
        'degree': e['degree'] ?? '',
        'start_date': e['start'] ?? '',
        'end_date': e['current'] == 'true' ? null : e['end'],
        'is_current': e['current'] == 'true',
      }).toList(),
      'projects': _projects.map((p) => {
        'name': p['name'] ?? '',
        'url': p['url'],
        'description': p['desc'] ?? '',
      }).toList(),
      'languages': _languages.map((l) => {
        'language': l['language'] ?? '',
        'proficiency': l['proficiency'] ?? '',
      }).toList(),
    };


    try {
      if (initialResume != null && initialResume.type == 'manual') {
        
        // Editando currículo manual existente → atualizar
        await provider.updateManualResume(
          resumeId: initialResume.id,
          resumeData: payload,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Currículo manual atualizado com sucesso!')),
          );
          Navigator.of(context).pop();
        }
      } else if (initialResume != null && initialResume.type == 'optimized') {
        // Editando currículo otimizado existente → atualizar como otimizado
        // Manter campos de otimização se existirem
        final optimizedPayload = {
          ...payload,
          'type': 'optimized',
          if (initialResume.optimizedText != null) 
            'optimized_text': initialResume.optimizedText,
          if (initialResume.suggestions != null)
            'suggestions': initialResume.suggestions,
          if (initialResume.score != null)
            'score': initialResume.score,
        };
        
        await provider.updateOptimizedResume(
          resumeId: initialResume.id,
          resumeData: optimizedPayload,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Currículo otimizado atualizado com sucesso!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        
        // Criando novo currículo manual
        await provider.createManualResume(payload);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Currículo salvo com sucesso!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditingOptimized = widget.initialResume?.type == 'optimized';
    final isEditingManual = widget.initialResume?.type == 'manual';
    
    String title;
    if (isEditingOptimized) {
      title = 'Edit Optimized Resume';
    } else if (isEditingManual) {
      title = 'Edit Resume';
    } else {
      title = 'Manual Resume';
    }
    
    return Scaffold(
      appBar: AppBar(title: Text(title)), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Step ${_currentStep + 1} of 6', style: const TextStyle(fontWeight: FontWeight.w600)), TextButton(onPressed: () { /* could skip */ }, child: const Text('Skip'))]),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _currentStep == 0 ? _personalStep() : _currentStep == 1 ? _summaryStep() : _currentStep == 2 ? _experienceStep() : _currentStep == 3 ? _educationStep() : _currentStep == 4 ? _projectsStep() : _languagesStep()))),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: OutlinedButton(onPressed: _back, child: const Text('Back'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _currentStep == 5 ? _finish : _next, child: Text(_currentStep == 5 ? 'Finish' : 'Next')))]),
          ]),
        ),
      ),
    );
  }
}
