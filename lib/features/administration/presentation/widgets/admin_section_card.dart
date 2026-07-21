import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'web_button.dart';

/// Shared white-box section card with a heading, matching the web panels'
/// "Add X" / "X List" boxes (`background: var(--surface); border: 1px
/// solid var(--line)`).
class AdminSectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const AdminSectionCard({super.key, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `Wrap` (not `Row`+`Expanded`) so a wide fixed-width trailing
          // widget (e.g. a 240px search box) flows to its own line on
          // narrow phones instead of squeezing the title into a
          // one-character-per-line overflow (the exact bug class fixed
          // previously in `schools_tab.dart`'s accordion headers).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Edit/Delete filled TEXT button pair — exact port of the web's Actions
/// column on Visitor Book, Phone Call Log and the Postal panels (plain
/// `buttonStyle("#0ea5e9")`/`buttonStyle("#dc2626")` "Edit"/"Delete"
/// buttons, not icons).
class AdminRowActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  const AdminRowActions({super.key, required this.onEdit, required this.onDelete, this.isDeleting = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        WebButton(label: 'Edit', color: const Color(0xFF0EA5E9), onPressed: onEdit),
        WebButton(
          label: isDeleting ? '...' : 'Delete',
          color: AppColors.dangerRed,
          onPressed: isDeleting ? null : onDelete,
        ),
      ],
    );
  }
}

/// Edit/Delete circular ICON button pair — exact port of the web
/// Complaints panel's `.action-btn-edit`/`.action-btn-delete` (32x32,
/// pencil/trash, `#e3f2fd`/`#1565c0` and `#ffebee`/`#c62828`).
class AdminIconActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  const AdminIconActionButtons({super.key, required this.onEdit, required this.onDelete, this.isDeleting = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.edit, size: 15, color: Color(0xFF1565C0)),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: isDeleting ? null : onDelete,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
            child: isDeleting
                ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete, size: 15, color: Color(0xFFC62828)),
          ),
        ),
      ],
    );
  }
}

/// Inline error/success banner shown above a form, matching the web's
/// red/green top banners.
class AdminMessageBanner extends StatelessWidget {
  final String? error;
  final String? success;

  const AdminMessageBanner({super.key, this.error, this.success});

  @override
  Widget build(BuildContext context) {
    if (error == null && success == null) return const SizedBox.shrink();
    final isError = error != null;
    final text = error ?? success!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.redSoft : AppColors.greenSoft,
        border: Border.all(color: isError ? AppColors.redBorder : AppColors.greenBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, color: isError ? const Color(0xFFB91C1C) : AppColors.greenDark),
      ),
    );
  }
}
