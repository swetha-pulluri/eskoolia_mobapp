import 'permission_tree.dart';

/// Mirrors frontend AssignPermissionPanel.tsx's OperationLevel type — the
/// three quick-apply presets shown per module.
enum OperationLevel { none, view, createEdit, full }

extension OperationLevelLabels on OperationLevel {
  String get label {
    switch (this) {
      case OperationLevel.none:
        return '';
      case OperationLevel.view:
        return 'View Only';
      case OperationLevel.createEdit:
        return 'Create & Edit';
      case OperationLevel.full:
        return 'Full Control';
    }
  }
}

/// One row of the "Page-Level Access" table — a feature/page grouped by its
/// view/add/edit/delete permissions. Mirrors frontend's SubFeatureRow +
/// groupPermsBySubFeature().
class SubFeatureRow {
  final String key;
  final String label;
  final PermissionNode? view;
  final PermissionNode? add;
  final PermissionNode? edit;
  final PermissionNode? delete;

  const SubFeatureRow({
    required this.key,
    required this.label,
    this.view,
    this.add,
    this.edit,
    this.delete,
  });
}

/// Module display-name overrides — ported verbatim from frontend
/// prettyModuleName() so labels match exactly.
const Map<String, String> _moduleNameOverrides = {
  'academics': 'Academics',
  'fees': 'Fees',
  'hr': 'HR',
  'transport': 'Transport',
  'inventory': 'Inventory',
  'admissions': 'Admissions',
  'admin_section': 'Administration',
  'access_control': 'Roles & Access',
  'students': 'Students',
  'timetable': 'Timetable',
  'communication': 'Communication',
  'accounts': 'Accounts',
  'library': 'Library',
  'examination': 'Examination',
  'behaviour': 'Behaviour',
  'reports': 'Reports',
  'dashboard': 'Dashboard',
  'payroll': 'Payroll',
  'finance': 'Finance',
};

/// Modules that handle financial/sensitive data — shown with a ⚠️ marker,
/// mirroring frontend RISKY_MODULES (the risky-module *confirmation modal*
/// before save is intentionally not ported — see AssignPermissionsSection
/// doc comment for why).
const Set<String> riskyModules = {
  'fees',
  'accounts',
  'finance',
  'payroll',
  'hr',
  'salary',
  'admin_section',
  'access_control',
};

String prettyModuleName(String module) {
  final override = _moduleNameOverrides[module];
  if (override != null) return override;
  return module
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Permission code format: "module.feature.action" — last segment is the
/// action (view/add/edit/delete/manage/read/...).
String _getActionFromCode(String code) {
  final parts = code.split('.');
  return parts.isEmpty ? 'view' : parts.last;
}

/// 3+ parts: module.feature.action → feature. 2 parts: module.action →
/// module (single-perm feature like "dashboard.view"). 1 part: as-is.
String _getFeatureKey(String code) {
  final parts = code.split('.');
  if (parts.length >= 3) return parts[parts.length - 2];
  if (parts.length == 2) return parts[0];
  return parts.isEmpty ? code : parts[0];
}

String _prettySubFeatureName(String featureKey) {
  return featureKey
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Groups a module's flat permission list into per-feature rows with
/// view/add/edit/delete columns — mirrors frontend groupPermsBySubFeature().
List<SubFeatureRow> groupPermsBySubFeature(List<PermissionNode> permissions) {
  final groups = <String, Map<String, PermissionNode>>{};
  final order = <String>[];

  for (final perm in permissions) {
    final rawAction = _getActionFromCode(perm.code);
    final featureKey = _getFeatureKey(perm.code);

    final String action;
    if (rawAction == 'add') {
      action = 'add';
    } else if (rawAction == 'edit') {
      action = 'edit';
    } else if (rawAction == 'delete') {
      action = 'delete';
    } else {
      action = 'view'; // "view", "manage", "read", etc.
    }

    if (!groups.containsKey(featureKey)) {
      groups[featureKey] = {};
      order.add(featureKey);
    }
    groups[featureKey]![action] = perm;
  }

  return order.map((key) {
    final acts = groups[key]!;
    return SubFeatureRow(
      key: key,
      label: _prettySubFeatureName(key),
      view: acts['view'],
      add: acts['add'],
      edit: acts['edit'],
      delete: acts['delete'],
    );
  }).toList();
}

/// Infers which OperationLevel preset the current selection matches for a
/// module — mirrors frontend inferOperationLevel().
OperationLevel inferOperationLevel(
  List<PermissionNode> permissions,
  Set<int> selectedIds,
) {
  final selected = permissions.where((p) => selectedIds.contains(p.id));
  if (selected.isEmpty) return OperationLevel.none;
  if (selected.any((p) => _getActionFromCode(p.code) == 'delete')) {
    return OperationLevel.full;
  }
  if (selected.any((p) {
    final a = _getActionFromCode(p.code);
    return a == 'add' || a == 'edit';
  })) {
    return OperationLevel.createEdit;
  }
  return OperationLevel.view;
}

/// Computes the new selected-id set for a module after applying a quick
/// OperationLevel preset — mirrors frontend applyOperationLevel().
Set<int> applyOperationLevel(
  PermissionModule module,
  OperationLevel level,
  Set<int> prevIds, {
  bool includeDelete = true,
}) {
  final next = {...prevIds};
  for (final p in module.permissions) {
    next.remove(p.id);
  }
  if (level == OperationLevel.none) return next;

  final rows = groupPermsBySubFeature(module.permissions);
  for (final row in rows) {
    if (level == OperationLevel.view) {
      if (row.view != null) next.add(row.view!.id);
    } else if (level == OperationLevel.createEdit) {
      if (row.view != null) next.add(row.view!.id);
      if (row.add != null) next.add(row.add!.id);
      if (row.edit != null) next.add(row.edit!.id);
    } else {
      if (row.view != null) next.add(row.view!.id);
      if (row.add != null) next.add(row.add!.id);
      if (row.edit != null) next.add(row.edit!.id);
      if (includeDelete && row.delete != null) next.add(row.delete!.id);
    }
  }
  return next;
}
