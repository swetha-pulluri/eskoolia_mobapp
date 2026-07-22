import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/models/role_data.dart';
import '../providers/roles_providers.dart';

/// Create New Role dialog — mirrors frontend AssignPermissionPanel.tsx's
/// `RoleFormModal` used in create mode (title "Create New Role", icon ✨).
///
/// The frontend also renders a second, simpler inline create-role form
/// directly inside its ModuleList role card (same `showNewRoleForm` state),
/// which would appear simultaneously with this modal on every trigger since
/// both are gated by the same flag — an apparent leftover from an
/// in-progress refactor (there's a `// TODO(create-role): restore these
/// props` comment beside it), not a deliberate two-form design. This dialog
/// implements the complete, validated one (matching the flow already used
/// for Edit Role) rather than reproducing that redundant double-render.
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

const Map<PortalType, String> _portalDropdownLabels = {
  PortalType.admin: 'Admin Console',
  PortalType.teacher: 'Teacher Portal',
  PortalType.parent: 'Parent Portal',
  PortalType.student: 'Student Portal',
  PortalType.custom: 'Custom',
};

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

  @override
  Widget build(BuildContext context) {
    final disabled = _nameController.text.trim().isEmpty || _saving;
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEAFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('✨', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Role',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Letters and spaces only — no numbers or special characters',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'ROLE NAME *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: _maxNameLength,
                onChanged: _handleNameChanged,
                onSubmitted: (_) {
                  if (!disabled) _handleCreate();
                },
                style: TextStyle(fontSize: 13, color: AppColors.inkPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Class Teacher, Lab Assistant, Principal…',
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _fieldError.isNotEmpty
                          ? AppColors.error
                          : const Color(0xFFD8D4FF),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _fieldError.isNotEmpty
                          ? AppColors.error
                          : AppColors.dashboardPurple,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _fieldError.isEmpty ? ' ' : _fieldError,
                      style: TextStyle(fontSize: 11, color: AppColors.error),
                    ),
                  ),
                  Text(
                    '${_nameController.text.length}/$_maxNameLength',
                    style: TextStyle(fontSize: 11, color: AppColors.inkTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'PORTAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: 6),
              AppDropdown<PortalType>(
                value: _portalType,
                items: PortalType.values
                    .map((type) => DropdownMenuItem<PortalType?>(
                          value: type,
                          child: Text(
                            _portalDropdownLabels[type] ?? type.label,
                            style: TextStyle(fontSize: 13, color: AppColors.inkPrimary),
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
                height: 48,
                fontSize: 13,
                textColor: AppColors.inkPrimary,
                borderColor: const Color(0xFFD8D4FF),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkSecondary,
                        side: BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: disabled ? null : _handleCreate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B4FCF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE8E8EE),
                        disabledForegroundColor: AppColors.inkTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create & Configure →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
