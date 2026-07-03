import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/transitions.dart';
import '../../models/onboarding_models.dart';
import '../../providers/onboarding_provider.dart';
import 'ats_loading_screen.dart';

class ManualResumeStepperScreen extends StatefulWidget {
  const ManualResumeStepperScreen({super.key});

  @override
  State<ManualResumeStepperScreen> createState() =>
      _ManualResumeStepperScreenState();
}

class _ManualResumeStepperScreenState
    extends State<ManualResumeStepperScreen> {
  int _currentStep = 0;

  // One GlobalKey<FormState> per step
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(5, (_) => GlobalKey<FormState>());

  // ─── Step 1: Basic info ────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // ─── Step 2: Summary ──────────────────────────────────────────────────────
  final _summaryCtrl = TextEditingController();

  // ─── Step 3: Experiences ──────────────────────────────────────────────────
  final List<_ExpControllers> _experiences = [];

  // ─── Step 4: Education ────────────────────────────────────────────────────
  final List<_EduControllers> _education = [];

  // ─── Step 5: Skills ───────────────────────────────────────────────────────
  final _skillInputCtrl = TextEditingController();
  final List<String> _skills = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _cityCtrl.dispose();
    _summaryCtrl.dispose();
    _skillInputCtrl.dispose();
    for (final e in _experiences) {
      e.dispose();
    }
    for (final e in _education) {
      e.dispose();
    }
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _addExperience() => setState(() => _experiences.add(_ExpControllers()));
  void _removeExperience(int i) {
    setState(() {
      _experiences[i].dispose();
      _experiences.removeAt(i);
    });
  }

  void _addEducation() => setState(() => _education.add(_EduControllers()));
  void _removeEducation(int i) {
    setState(() {
      _education[i].dispose();
      _education.removeAt(i);
    });
  }

  void _addSkill() {
    final skill = _skillInputCtrl.text.trim();
    if (skill.isEmpty) return;
    setState(() {
      _skills.add(skill);
      _skillInputCtrl.clear();
    });
  }

  void _removeSkill(int i) => setState(() => _skills.removeAt(i));

  bool _validateCurrentStep() {
    return _formKeys[_currentStep].currentState?.validate() ?? true;
  }

  void _onStepContinue() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _submit() {
    final form = ManualResumeForm(
      name: _nameCtrl.text.trim(),
      targetRole: _roleCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      experiences: _experiences
          .map(
            (e) => ExperienceEntry(
              role: e.role.text.trim(),
              company: e.company.text.trim(),
              period: e.period.text.trim(),
              description: e.description.text.trim(),
            ),
          )
          .toList(),
      education: _education
          .map(
            (e) => EducationEntry(
              institution: e.institution.text.trim(),
              degree: e.degree.text.trim(),
              period: e.period.text.trim(),
            ),
          )
          .toList(),
      skills: List.from(_skills),
    );

    context.read<OnboardingProvider>().setResumeText(buildResumeText(form));
    Navigator.of(context).pushReplacement(
      AppTransitions.fadeSlide(const AtsLoadingScreen()),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Fill in Resume'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        onStepTapped: (step) {
          if (step <= _currentStep) setState(() => _currentStep = step);
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 4;
          final isOptional = _currentStep == 2 || _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(
                          isLast ? 'Analyze Resume' : 'Continue',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(
                        _currentStep == 0 ? 'Cancel' : 'Back',
                      ),
                    ),
                  ],
                ),
                if (isOptional) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      if (_currentStep < 4) {
                        setState(() => _currentStep++);
                      } else {
                        _submit();
                      }
                    },
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          _step0BasicInfo(),
          _step1Summary(),
          _step2Experience(),
          _step3Education(),
          _step4Skills(),
        ],
      ),
    );
  }

  // ─── Steps ────────────────────────────────────────────────────────────────

  Step _step0BasicInfo() {
    return Step(
      title: const Text('Basic Info'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKeys[0],
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Desired Role *',
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Step _step1Summary() {
    return Step(
      title: const Text('Professional Summary'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKeys[1],
        child: TextFormField(
          controller: _summaryCtrl,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Objective / Summary *',
            alignLabelWithHint: true,
            hintText:
                'Briefly describe your experience, goals, and highlights...',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required field' : null,
        ),
      ),
    );
  }

  Step _step2Experience() {
    return Step(
      title: const Text('Work Experience'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_experiences.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No experience added yet.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
              ),
            for (int i = 0; i < _experiences.length; i++)
              _ExperienceCard(
                index: i,
                controllers: _experiences[i],
                onRemove: () => _removeExperience(i),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Experience'),
              onPressed: _addExperience,
            ),
          ],
        ),
      ),
    );
  }

  Step _step3Education() {
    return Step(
      title: const Text('Education'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_education.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No education added yet.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
              ),
            for (int i = 0; i < _education.length; i++)
              _EducationCard(
                index: i,
                controllers: _education[i],
                onRemove: () => _removeEducation(i),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Education'),
              onPressed: _addEducation,
            ),
          ],
        ),
      ),
    );
  }

  Step _step4Skills() {
    return Step(
      title: const Text('Skills'),
      isActive: _currentStep >= 4,
      content: Form(
        key: _formKeys[4],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillInputCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add Skill',
                      hintText: 'e.g. Python, Leadership...',
                    ),
                    onFieldSubmitted: (_) => _addSkill(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: _addSkill,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_skills.isEmpty)
              Text(
                'Add at least one skill.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _skills.length; i++)
                  Chip(
                    label: Text(_skills[i]),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeSkill(i),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                    labelStyle: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Controller bundles ─────────────────────────────────────────────────────

class _ExpControllers {
  final company = TextEditingController();
  final role = TextEditingController();
  final period = TextEditingController();
  final description = TextEditingController();

  void dispose() {
    company.dispose();
    role.dispose();
    period.dispose();
    description.dispose();
  }
}

class _EduControllers {
  final institution = TextEditingController();
  final degree = TextEditingController();
  final period = TextEditingController();

  void dispose() {
    institution.dispose();
    degree.dispose();
    period.dispose();
  }
}

// ─── Experience card ─────────────────────────────────────────────────────────

class _ExperienceCard extends StatelessWidget {
  final int index;
  final _ExpControllers controllers;
  final VoidCallback onRemove;

  const _ExperienceCard({
    required this.index,
    required this.controllers,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Experience ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: controllers.company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Company *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.role,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Role *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.period,
              decoration: const InputDecoration(
                labelText: 'Period',
                hintText: 'e.g. Jan 2020 – Dec 2022',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description of activities',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Education card ───────────────────────────────────────────────────────────

class _EducationCard extends StatelessWidget {
  final int index;
  final _EduControllers controllers;
  final VoidCallback onRemove;

  const _EducationCard({
    required this.index,
    required this.controllers,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: controllers.institution,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Institution *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.degree,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Course / Degree *',
                hintText: 'e.g. Bachelor in Computer Science',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.period,
              decoration: const InputDecoration(
                labelText: 'Period',
                hintText: 'e.g. 2018 – 2022',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
