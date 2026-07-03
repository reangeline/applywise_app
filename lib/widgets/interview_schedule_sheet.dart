import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../models/job_application.dart';
import '../providers/pipeline_provider.dart';
import '../services/pipeline_service.dart';

class InterviewScheduleSheet extends StatefulWidget {
  final JobApplication job;
  final void Function(JobApplication updated) onJobUpdated;

  const InterviewScheduleSheet({
    super.key,
    required this.job,
    required this.onJobUpdated,
  });

  @override
  State<InterviewScheduleSheet> createState() => _InterviewScheduleSheetState();
}

class _InterviewScheduleSheetState extends State<InterviewScheduleSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _interviewType = 'technical';
  bool _isSaving = false;

  static const _interviewTypes = {
    'phone_screen': 'Phone screen',
    'technical': 'Technical',
    'hr': 'HR',
    'final_round': 'Final round',
  };

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _scheduleLocalReminder(DateTime interviewDateTime) async {
    try {
      final reminderTime =
          interviewDateTime.subtract(const Duration(hours: 1));
      if (reminderTime.isBefore(DateTime.now())) return;

      final plugin = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        'interview_reminders',
        'Interview Reminders',
        channelDescription: 'Reminders for upcoming interviews',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
          android: androidDetails, iOS: darwinDetails);

      // Schedule as a simple notification shown after a delay
      final delayMs =
          reminderTime.difference(DateTime.now()).inMilliseconds;
      if (delayMs > 0) {
        Future.delayed(Duration(milliseconds: delayMs), () async {
          await plugin.show(
            widget.job.id.hashCode,
            'Interview in 1 hour',
            '${_interviewTypes[_interviewType] ?? _interviewType} interview at ${widget.job.companyName}',
            details,
          );
        });
      }
    } catch (_) {
      // Reminder scheduling is best-effort
    }
  }

  Future<void> _save() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final combined = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() => _isSaving = true);
    try {
      // Sync job to backend first if it was added offline (id is empty)
      final pipeline = Provider.of<PipelineProvider>(context, listen: false);
      final job = await pipeline.syncJobIfNeeded(widget.job);
      final resolvedJobId = job.id.trim();
      if (resolvedJobId.isEmpty) {
        throw Exception('Could not resolve a valid job id for this interview');
      }

      final updated = await PipelineService()
          .logInterview(resolvedJobId, combined, _interviewType);
      if (!mounted) return;

      // If backend didn't return timeline events, add one client-side
      final typeLabel = _interviewTypes[_interviewType] ?? _interviewType;
      final hasEvent = updated.timeline.any((e) => e.type == 'interview_scheduled');
      final finalJob = hasEvent
          ? updated
          : updated.copyWith(
              timeline: [
                ...job.timeline,
                TimelineEvent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: 'interview_scheduled',
                  label: '$typeLabel interview scheduled',
                  detail: '${_formatDate(combined)} at ${_formatTime(_selectedTime!)}',
                  createdAt: DateTime.now(),
                ),
              ],
            );

      widget.onJobUpdated(finalJob);
      await _scheduleLocalReminder(combined);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Interview logged. Reminder set for 1 hour before.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canSave = _selectedDate != null && _selectedTime != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Log interview',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Date field
                  GestureDetector(
                    onTap: _pickDate,
                    child: _fieldContainer(
                      cs: cs,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: cs.primary),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDate != null
                                ? _formatDate(_selectedDate!)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedDate != null
                                  ? cs.onSurface
                                  : cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Time field
                  GestureDetector(
                    onTap: _pickTime,
                    child: _fieldContainer(
                      cs: cs,
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: cs.primary),
                          const SizedBox(width: 10),
                          Text(
                            _selectedTime != null
                                ? _formatTime(_selectedTime!)
                                : 'Select time',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedTime != null
                                  ? cs.onSurface
                                  : cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Interview type
                  Text(
                    'Interview type',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interviewTypes.entries.map((entry) {
                      final isActive = _interviewType == entry.key;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _interviewType = entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isActive ? cs.primary : Colors.transparent,
                            border: Border.all(
                              color: isActive
                                  ? cs.primary
                                  : cs.outline.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (canSave && !_isSaving) ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        disabledBackgroundColor:
                            cs.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: cs.onPrimary, strokeWidth: 2),
                            )
                          : const Text('Save interview'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _fieldContainer({
    required ColorScheme cs,
    required Widget child,
  }) =>
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: child,
      );
}

