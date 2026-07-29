import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/models/role_data.dart';
import '../providers/roles_providers.dart';

/// Create New Role — mirrors the real, current frontend: the "+ New Role"
/// slide-in editor panel in `frontend/components/access-control/
/// RoleManagementPanel.tsx` (`panelMode === "add"`), which on desktop
/// appears as a 290px panel docked beside the roles grid (`display:flex`
/// split layout). On a phone-width screen that side-by-side layout has no
/// room to exist, so — matching this same page's own established mobile
/// adaptation for "Assign Permissions" (a tab swap instead of the frontend's
/// side panel) — this renders as a modal instead of a docked panel. The
/// panel's own content (header bar, copy, field order, validation, hint
/// box, button labels) is copied exactly.
///
/// POST /roles/ (RoleViewSet.create), scoped to the caller's school by the
/// backend's perform_create — see backend/apps/access_control/views.py.
class RoleCreateDialog extends ConsumerStatefulWidget {
  const RoleCreateDialog({super.key});

  /// Shows the dialog and returns the created [RoleData] on success, or null
  /// if cancelled/dismissed.
  static Future<RoleData?> show(BuildContext context) {
    return showDialog<RoleData>(
      context: context,
      barrierColor: const Color(0x8C0F112A), // rgba(15,17,42,.55) — frontend ModalOverlay
      builder: (_) => const RoleCreateDialog(),
    );
  }

  @override
  ConsumerState<RoleCreateDialog> createState() => _RoleCreateDialogState();
}

const int _maxNameLength = 30;

// Long-form dropdown label per PortalType — mirrors PORTAL_OPTIONS[].label in
// RoleManagementPanel.tsx (distinct from RoleData's own short `.label`, e.g.
// "Admin", which mirrors that same frontend file's separate PORTAL_BADGE map
// used for role-card badges, not this dropdown).
const Map<PortalType, String> _portalDropdownLabels = {
  PortalType.admin: 'Admin Console',
  PortalType.teacher: 'Teacher Portal',
  PortalType.parent: 'Parent Portal',
  PortalType.student: 'Student Portal',
  PortalType.custom: 'Custom',
};

/// "{label} — {description}", matching `PORTAL_OPTIONS.map(opt => \`${opt.label} — ${opt.description}\`)`.
String _portalOptionText(PortalType type) =>
    '${_portalDropdownLabels[type] ?? type.label} — ${type.description}';

bool _isValidRoleName(String value) => RegExp(r'^[A-Za-z ]+$').hasMatch(value);

/// True when 3+ of the same letter appear consecutively (e.g. "www").
bool _hasRepeatedChars(String value) =>
    RegExp(r'(.)\1{2,}', caseSensitive: false).hasMatch(value);

class _RoleCreateDialogState extends ConsumerState<RoleCreateDialog> {
  final TextEditingController _nameController = TextEditingController();
  PortalType _portalType = PortalType.admin;
  bool _saving = false;
  String _fieldError = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleNameChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z ]'), '');
    final truncated = cleaned.length > _maxNameLength
        ? cleaned.substring(0, _maxNameLength)
        : cleaned;
    if (truncated != value) {
      _nameController.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
    setState(() {
      _fieldError = truncated.trim().isNotEmpty && _hasRepeatedChars(truncated)
          ? 'Avoid repeating the same letter more than twice (e.g. "wwwwww")'
          : '';
    });
  }

  Future<void> _handleCreate() async {
    final normalized = _nameController.text.trim();
    if (normalized.isEmpty) {
      setState(() => _fieldError = 'Role name is required.');
      return;
    }
    if (!_isValidRoleName(normalized)) {
      setState(
        () => _fieldError =
            'Only letters and spaces are allowed. No numbers or special characters.',
      );
      return;
    }
    if (_hasRepeatedChars(normalized)) {
      setState(
        () => _fieldError =
            'Avoid repeating the same letter more than twice (e.g. "wwwwww")',
      );
      return;
    }

    setState(() {
      _fieldError = '';
      _saving = true;
    });

    try {
      final created = await ref
          .read(roleRepositoryProvider)
          .createRole(name: normalized, portalType: _portalType);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _saving = false;
        _fieldError = message;
      });
    }
  }

  // Exact token values from RoleManagementPanel.tsx's slide-in panel (not
  // AppColors' generic ink*/error aliases, which belong to other pages and
  // don't match this panel's real --ink-1/2/3, --bd, --bg-2 values).
  static const _ink1 = Color(0xFF0F1222);
  static const _ink2 = Color(0xFF5A607A);
  static const _ink3 = Color(0xFF9197AE);
  static const _bd = Color(0xFFECECF2);
  static const _bg2 = Color(0xFFF4F4F8);
  static const _puSoft = Color(0xFFEEEAFF);
  static const _puDeep = Color(0xFF4F35CC);
  static const _puBorder = Color(0xFFC4B5FD);

  @override
  Widget build(BuildContext context) {
    final disabled = _nameController.text.trim().isEmpty || _saving;
    final atMaxLength = _nameController.text.length >= _maxNameLength;
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.dashboardPurple, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar — matches the panel's own header exactly
              // (background: var(--pu-soft), text: var(--pu-deep), a bottom
              // border in a lighter purple, and a plain "×" close button).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  color: _puSoft,
                  border: Border(bottom: BorderSide(color: _puBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '+ New Role',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _puDeep),
                    ),
                    GestureDetector(
                      onTap: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('×', style: TextStyle(fontSize: 18, color: _ink3, height: 1)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ROLE NAME *',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: _ink3),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      maxLength: _maxNameLength,
                      onChanged: _handleNameChanged,
                      onSubmitted: (_) {
                        if (!disabled) _handleCreate();
                      },
                      style: const TextStyle(fontSize: 12, color: _ink1),
                      decoration: InputDecoration(
                        hintText: 'e.g. Sports Coordinator',
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _fieldError.isNotEmpty ? AppColors.error : _bd),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _fieldError.isNotEmpty ? AppColors.error : AppColors.dashboardPurple,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _fieldError.isEmpty ? 'Letters and spaces only' : _fieldError,
                            style: TextStyle(fontSize: 11, color: _fieldError.isEmpty ? _ink3 : AppColors.error),
                          ),
                        ),
                        Text(
                          '${_nameController.text.length}/$_maxNameLength',
                          style: TextStyle(fontSize: 11, color: atMaxLength ? AppColors.error : _ink3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: _ink3),
                        children: [
                          TextSpan(text: 'PORTAL '),
                          TextSpan(text: '*', style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.error)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    AppDropdown<PortalType>(
                      value: _portalType,
                      items: PortalType.values
                          .map((type) => DropdownMenuItem<PortalType?>(
                                value: type,
                                child: Text(
                                  _portalOptionText(type),
                                  style: const TextStyle(fontSize: 12, color: _ink1),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _portalType = value);
                              }
                            },
                      height: 44,
                      fontSize: 12,
                      textColor: _ink1,
                      borderColor: _bd,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Controls which portal users with this role are sent to after login.',
                      style: TextStyle(fontSize: 10, color: _ink3, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(8)),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 11, color: _ink2),
                          children: [
                            TextSpan(text: 'Set the '),
                            TextSpan(text: 'Portal', style: TextStyle(fontWeight: FontWeight.w700, color: _ink1)),
                            TextSpan(
                              text: ' above first — it cannot be inferred from the name. Then use \u{1F511} to assign permissions.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink2,
                              side: const BorderSide(color: _bd),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: disabled ? null : _handleCreate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.dashboardPurple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE8E8EE),
                              disabledForegroundColor: _ink3,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Create Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
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
}
