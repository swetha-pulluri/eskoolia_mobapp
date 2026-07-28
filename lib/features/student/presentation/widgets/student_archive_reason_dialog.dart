import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

const List<String> _presetReasons = [
  'Transferred to another school',
  'Graduated / completed schooling',
  'Withdrawn by guardian',
  'Duplicate record',
  'Other',
];

/// Archive reason picker — mirrors frontend StudentListPanel.tsx's custom
/// reason-picker modal used before Archive/Deactivate. Returns the chosen
/// reason string, or null if cancelled.
Future<String?> showStudentArchiveReasonDialog(
  BuildContext context, {
  required int count,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ArchiveReasonDialog(count: count),
  );
}

class _ArchiveReasonDialog extends StatefulWidget {
  final int count;
  const _ArchiveReasonDialog({required this.count});

  @override
  State<_ArchiveReasonDialog> createState() => _ArchiveReasonDialogState();
}

class _ArchiveReasonDialogState extends State<_ArchiveReasonDialog> {
  String? _selected;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String? get _finalReason {
    if (_selected == null) return null;
    if (_selected == 'Other') {
      final custom = _customController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _selected;
  }

  @override
  Widget build(BuildContext context) {
    final reason = _finalReason;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.studentStatusArchivedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🗄', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(height: 14),
              Text(
                widget.count == 1
                    ? 'Archive this student?'
                    : 'Archive ${widget.count} students?',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.studentListInk,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a reason for the record. This can be undone from the Archived filter.',
                style: TextStyle(fontSize: 13, color: AppColors.studentListMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              ..._presetReasons.map((reasonOption) {
                final isSelected = _selected == reasonOption;
                return InkWell(
                  onTap: () => setState(() => _selected = reasonOption),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? AppColors.studentListBrand : AppColors.studentListLine,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reasonOption,
                            style: const TextStyle(fontSize: 13, color: AppColors.studentListInk),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_selected == 'Other') ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _customController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe the reason…',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.studentFieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.studentListBrand),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.studentListMuted,
                        side: BorderSide(color: AppColors.studentListLine),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: reason == null
                          ? null
                          : () => Navigator.of(context).pop(reason),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE8E8EE),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Archive'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
