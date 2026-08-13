import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/broadcast_entity.dart';
import '../providers/broadcast_providers.dart';

class BroadcastTemplate {
  final String id;
  final String emoji;
  final String label;
  final String message;
  const BroadcastTemplate({required this.id, required this.emoji, required this.label, required this.message});
}

/// Exact preset strings ported from web's `QuickBroadcast.tsx` `TEMPLATES`
/// — the `{placeholder}` tokens are left as literal text for the teacher
/// to edit, matching web (they are not auto-filled).
const List<BroadcastTemplate> broadcastTemplates = [
  BroadcastTemplate(
    id: 'bus_delay',
    emoji: '🚌',
    label: 'Bus delay',
    message: 'Dear Parent, Bus Route {route} is running approximately {minutes} minutes late today. We apologize for the inconvenience.',
  ),
  BroadcastTemplate(
    id: 'closure',
    emoji: '🌧',
    label: 'Closure',
    message: 'Dear Parent, school will remain closed tomorrow due to {reason}. Regular classes will resume on {date}.',
  ),
  BroadcastTemplate(
    id: 'exam_remind',
    emoji: '📋',
    label: 'Exam reminder',
    message: 'Dear Parent, {exam} is scheduled on {date}. Please ensure your child carries their admit card and stationery.',
  ),
  BroadcastTemplate(
    id: 'event',
    emoji: '🎉',
    label: 'Event',
    message: 'Dear Parent, {event_name} is scheduled on {date} at {time}. We look forward to your participation.',
  ),
  BroadcastTemplate(
    id: 'fee_due',
    emoji: '💰',
    label: 'Fee due',
    message: 'Dear Parent, the fee for {term} is due by {due_date}. Please pay at the school office or online portal.',
  ),
  BroadcastTemplate(id: 'custom', emoji: '✏️', label: 'Custom', message: ''),
];

const _channelLabels = {'push': 'App / Web notification', 'sms': 'SMS', 'email': 'Email'};

Future<void> showBroadcastComposeSheet(BuildContext context, BroadcastTemplate template) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ComposeSheet(template: template),
  );
}

class _ComposeSheet extends ConsumerStatefulWidget {
  final BroadcastTemplate template;
  const _ComposeSheet({required this.template});

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  late final TextEditingController _messageController = TextEditingController(text: widget.template.message);
  final Set<String> _channels = {'push'};
  bool _scheduleMode = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _sending = false;
  String? _resultMessage;
  bool _resultIsError = false;
  Set<int> _selectedClassIds = {};

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(audienceOptionsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => optionsAsync.when(
        data: (options) => _buildForm(context, scrollController, options),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(fontSize: 12, color: AppColors.error))),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ScrollController scrollController, BroadcastAudienceOptionsEntity options) {
    if (options.isTeacher && _selectedClassIds.isEmpty) {
      _selectedClassIds = options.classes.map((c) => c.id).toSet();
    }
    final audienceType = options.audienceTypes.isNotEmpty ? options.audienceTypes.first : 'class_parents';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(widget.template.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.template.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1))),
              InkWell(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, size: 18, color: AppColors.ink3)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('MESSAGE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.ink3)),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                maxLines: 7,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg2,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('CHANNELS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.ink3)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _channelLabels.entries) _channelPill(entry.key, entry.value),
                ],
              ),
              if (_channels.contains('sms')) ...[
                const SizedBox(height: 8),
                const Text(
                  "SMS is logged for the school's records but not yet dispatched through an SMS provider — recipients will only be notified via the other selected channels.",
                  style: TextStyle(fontSize: 11, color: AppColors.ink3),
                ),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _scheduleMode,
                onChanged: (v) => setState(() => _scheduleMode = v ?? false),
                title: const Text('Schedule for later', style: TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_scheduleMode)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _scheduledDate ?? now,
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _scheduledDate = picked);
                        },
                        child: Text(_scheduledDate == null ? 'Pick date' : '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _scheduledTime ?? TimeOfDay.now());
                          if (picked != null) setState(() => _scheduledTime = picked);
                        },
                        child: Text(_scheduledTime == null ? 'Pick time' : _scheduledTime!.format(context)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              const Text('AUDIENCE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.ink3)),
              const SizedBox(height: 6),
              if (options.isTeacher)
                const Text(
                  "As a class teacher, you can broadcast to parents of the class(es) you're assigned to.",
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink2),
                )
              else
                Wrap(
                  spacing: 6,
                  children: [for (final type in options.audienceTypes) Text(type, style: const TextStyle(fontSize: 12))],
                ),
              if (options.classes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final c in options.classes) _classPill(c)],
                ),
              ] else if (options.isTeacher)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No classes available.', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                ),
              if (_resultMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _resultIsError ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_resultMessage!, style: TextStyle(fontSize: 12.5, color: _resultIsError ? AppColors.error : AppColors.success)),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : () => _send(audienceType),
                  icon: Icon(_scheduleMode ? Icons.schedule : Icons.send, size: 16),
                  label: Text(_sending ? 'Sending…' : (_scheduleMode ? 'Schedule' : 'Send Now')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPurple, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _channelPill(String key, String label) {
    final selected = _channels.contains(key);
    return InkWell(
      onTap: () => setState(() => selected ? _channels.remove(key) : _channels.add(key)),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPurple : AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.ink2)),
      ),
    );
  }

  Widget _classPill(BroadcastClassEntity classEntity) {
    final selected = _selectedClassIds.contains(classEntity.id);
    return InkWell(
      onTap: () => setState(() => selected ? _selectedClassIds.remove(classEntity.id) : _selectedClassIds.add(classEntity.id)),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleSoft : AppColors.bg2,
          border: Border.all(color: selected ? AppColors.brandPurple : Colors.transparent),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(classEntity.name, style: TextStyle(fontSize: 12, color: selected ? AppColors.brandPurple : AppColors.ink2)),
      ),
    );
  }

  Future<void> _send(String audienceType) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _resultIsError = true;
        _resultMessage = 'Write a message first.';
      });
      return;
    }
    if (audienceType == 'class_parents' && _selectedClassIds.isEmpty) {
      setState(() {
        _resultIsError = true;
        _resultMessage = 'Select at least one class.';
      });
      return;
    }
    DateTime? scheduledAt;
    if (_scheduleMode) {
      if (_scheduledDate == null || _scheduledTime == null) {
        setState(() {
          _resultIsError = true;
          _resultMessage = 'Pick a date and time to schedule.';
        });
        return;
      }
      scheduledAt = DateTime(_scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day, _scheduledTime!.hour, _scheduledTime!.minute);
      if (!scheduledAt.isAfter(DateTime.now())) {
        setState(() {
          _resultIsError = true;
          _resultMessage = 'Scheduled time must be in the future.';
        });
        return;
      }
      if (scheduledAt.isAfter(DateTime.now().add(const Duration(days: 365)))) {
        setState(() {
          _resultIsError = true;
          _resultMessage = 'Scheduled date must be within 1 year from today.';
        });
        return;
      }
    }

    setState(() {
      _sending = true;
      _resultMessage = null;
    });
    try {
      final result = await ref.read(broadcastRepositoryProvider).sendBroadcast(
            message: message,
            template: widget.template.id,
            audienceType: audienceType,
            classIds: _selectedClassIds.toList(),
            channels: _channels.toList(),
            scheduledAt: scheduledAt,
          );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _resultIsError = false;
        _resultMessage = result.message;
      });
      if (result.status == 'sent') {
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _resultIsError = true;
        _resultMessage = '$e';
      });
    }
  }
}
