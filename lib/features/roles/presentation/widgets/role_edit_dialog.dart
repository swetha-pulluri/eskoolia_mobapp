import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/role_data.dart';
import '../providers/roles_providers.dart';

/// Edit Role dialog — mirrors frontend RoleManagementPanel.tsx's slide-in
/// editor panel (panelMode 'edit'). The frontend shows this as a side panel
/// next to the card grid; on mobile it's a modal dialog instead, but the
/// fields, validation, and copy match exactly.
///
/// Fetches the role's full detail on open (GET /roles/{id}/) rather than
/// trusting the portalType already on the card: the list endpoint the card
/// grid uses is fetched with `minimal=1`, which omits portal_type entirely.
/// The frontend's own edit panel has a latent bug here — it seeds the portal
/// dropdown straight from the already-loaded (portal_type-less) list row,
/// silently defaulting every edit to 'admin'. Fetching the detail avoids
/// replicating that bug, which would otherwise silently corrupt a role's
/// portal type on every edit.
class RoleEditDialog extends ConsumerStatefulWidget {
  final RoleData role;

  const RoleEditDialog({super.key, required this.role});

  /// Shows the dialog and returns the updated [RoleData] on success, or null
  /// if cancelled/dismissed.
  static Future<RoleData?> show(BuildContext context, {required RoleData role}) {
    return showDialog<RoleData>(
      context: context,
      builder: (_) => RoleEditDialog(role: role),
    );
  }

  @override
  ConsumerState<RoleEditDialog> createState() => _RoleEditDialogState();
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

class _RoleEditDialogState extends ConsumerState<RoleEditDialog> {
  late final TextEditingController _nameController;
  late PortalType _portalType;
  late bool _isActive;

  bool _loadingDetail = true;
  String? _loadError;
  bool _saving = false;
  String _fieldError = '';
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role.name);
    _isActive = widget.role.isActive;
    _portalType = widget.role.portalType ?? PortalType.admin;
    _loadDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ref
          .read(roleRepositoryProvider)
          .fetchRoleDetail(widget.role.id);
      if (!mounted) return;
      setState(() {
        _portalType = detail.portalType ?? PortalType.admin;
        _isActive = detail.isActive;
        _loadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loadingDetail = false;
      });
    }
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
      _fieldError = _hasRepeatedChars(truncated)
          ? 'Avoid repeating the same letter more than twice (e.g. "wwwwww")'
          : '';
      _saveError = null;
    });
  }

  Future<void> _handleSave() async {
    final normalized = _nameController.text.trim();
    if (normalized.isEmpty) {
      setState(() => _fieldError = 'Role name is required.');
      return;
    }
    if (normalized.length > _maxNameLength) {
      setState(
        () => _fieldError = 'Role name cannot exceed $_maxNameLength characters.',
      );
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
      _saveError = null;
      _saving = true;
    });

    try {
      final updated = await ref
          .read(roleRepositoryProvider)
          .updateRole(
            widget.role.id,
            name: normalized,
            isActive: _isActive,
            portalType: _portalType,
          );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _saving = false;
        _saveError = message;
        if (message.toLowerCase().contains('name')) _fieldError = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _loadingDetail
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _loadError != null
                    ? _buildLoadError()
                    : _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border(bottom: BorderSide(color: const Color(0xFFC4B5FD))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '✏ Edit Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.dashboardPurple,
              ),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.textTertiary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _loadError!,
          style: TextStyle(fontSize: 13, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() {
            _loadingDetail = true;
            _loadError = null;
            _loadDetail();
          }),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Role Name
        Text(
          'ROLE NAME *',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          onChanged: _handleNameChanged,
          maxLength: _maxNameLength,
          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Sports Coordinator',
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
                    : AppColors.cardBorder,
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
                _fieldError.isNotEmpty ? _fieldError : 'Letters and spaces only',
                style: TextStyle(
                  fontSize: 11,
                  color: _fieldError.isNotEmpty
                      ? AppColors.error
                      : AppColors.textTertiary,
                ),
              ),
            ),
            Text(
              '${_nameController.text.length}/$_maxNameLength',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Portal
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textTertiary,
            ),
            children: const [
              TextSpan(text: 'PORTAL '),
              TextSpan(
                text: '*',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PortalType>(
              value: _portalType,
              isExpanded: true,
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _portalType = value);
                    },
              items: PortalType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    '${_portalDropdownLabels[type]} — ${type.description}',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Controls which portal users with this role are sent to after login.',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.4),
        ),
        const SizedBox(height: 16),

        // Status
        Text(
          'STATUS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _saving ? null : () => setState(() => _isActive = !_isActive),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isActive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              border: Border.all(
                color: _isActive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isActive ? Icons.circle : Icons.circle_outlined,
                  size: 8,
                  color: _isActive
                      ? const Color(0xFF166534)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isActive
                        ? const Color(0xFF166534)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_saveError != null) ...[
          const SizedBox(height: 12),
          Text(
            _saveError!,
            style: TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dashboardPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
