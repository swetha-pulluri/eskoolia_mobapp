import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'web_button.dart';

/// Shared shell for the "numbered stepper" Administration screens that
/// were rebuilt on the real, currently-shipped web design
/// (`VisitorBookPanel.module.css`, reused verbatim by `ComplaintPanel.tsx`,
/// `PhoneCallLogPanel.tsx`, `PostalReceivePanel.tsx`,
/// `PostalDispatchPanel.tsx`, `AdminSetupPanel.tsx`) — a `01/02/03` tab
/// nav, an "assign card" add/edit form, an optional collapsible "Smart
/// Filter" section, and a "Browse" list section. Admin Setup only has 2
/// steps (no Smart Filter); every other stepper screen has 3.
class AdminStep {
  final String number;
  final IconData icon;
  final String label;
  const AdminStep({required this.number, required this.icon, required this.label});
}

class AdminStepperNav extends StatelessWidget {
  final List<AdminStep> steps;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const AdminStepperNav({super.key, required this.steps, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final active = i == activeIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  // Matches web's `.navTabActive` exactly
                  // (`VisitorBookPanel.module.css`): `background: var(--ink)
                  // !important` where `--ink: #19162c` + white text — not a
                  // white raised pill with purple text.
                  color: active ? const Color(0xFF19162C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(step.number,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : AppColors.textTertiary)),
                        const SizedBox(width: 4),
                        Icon(step.icon, size: 13, color: active ? Colors.white : AppColors.textTertiary),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Section 01 — the "assignCard" add/edit form: title + subtitle, an
/// optional "Editing X: {value}" chip, a red validation banner, the
/// caller's field widgets, then a footer row (helper text + Reset/Cancel +
/// Save/Update button with a checkmark icon).
class AdminStepFormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? editingBadgeText;
  final String? banner;
  final List<Widget> fields;
  final String footerHelperText;
  final bool isEditing;
  final bool saving;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const AdminStepFormCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.editingBadgeText,
    this.banner,
    required this.fields,
    required this.footerHelperText,
    required this.isEditing,
    required this.saving,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          if (editingBadgeText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 12, color: AppColors.primaryPurple),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(editingBadgeText!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (banner != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                border: Border.all(color: const Color(0xFFFFD0CC)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(banner!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.dangerRed)),
            ),
          ...fields,
          const Divider(height: 24),
          Text(footerHelperText, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              WebButton(label: isEditing ? 'Cancel' : 'Reset', color: const Color(0xFF6B7280), onPressed: onReset),
              ElevatedButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving ? const SizedBox.shrink() : const Icon(Icons.check, size: 14),
                label: Text(saving ? 'Saving...' : (isEditing ? 'Update' : 'Save')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryPurple.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(140, 36),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section 02 — the collapsible "Smart filters" trigger + body. The
/// caller supplies the filter field widgets and the chip list; Apply/Clear
/// wiring is left to the caller since each screen's filter set differs.
class AdminSmartFilterSection extends StatelessWidget {
  final String stepNumber;
  final String subtitle;
  final bool open;
  final VoidCallback onToggle;
  final List<String> chips;
  final ValueChanged<String> onRemoveChip;
  final VoidCallback onClearAll;
  final List<Widget> fields;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const AdminSmartFilterSection({
    super.key,
    required this.stepNumber,
    required this.subtitle,
    required this.open,
    required this.onToggle,
    required this.chips,
    required this.onRemoveChip,
    required this.onClearAll,
    required this.fields,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(6)),
                    child: Text(stepNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Smart filters', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...chips.map((c) => _chip(c)),
                  TextButton(onPressed: onClearAll, child: const Text('Clear', style: TextStyle(fontSize: 11.5))),
                ],
              ),
            ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20),
                  ...fields,
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      WebButton(label: 'Clear filters', color: const Color(0xFF6B7280), onPressed: onClear),
                      WebButton(label: 'Apply Filters', onPressed: onApply),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
          const SizedBox(width: 5),
          InkWell(onTap: () => onRemoveChip(label), child: const Text('✕', style: TextStyle(fontSize: 11, color: Colors.white))),
        ],
      ),
    );
  }
}

/// Section 03 — the "Browse ___ List" heading (step badge + title + the
/// literal em-dash caption web always uses).
class AdminBrowseHeading extends StatelessWidget {
  final String stepNumber;
  final String title;

  const AdminBrowseHeading({super.key, required this.stepNumber, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(6)),
            child: Text(stepNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Text('— view, edit, or delete existing records.', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
