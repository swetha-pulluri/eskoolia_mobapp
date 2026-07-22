import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../login_permission/domain/models/login_permission_user.dart';

class LoginPermissionFilterBar extends StatelessWidget {
  final String roleFilter;
  final String searchQuery;
  final StatusFilter statusFilter;
  final Function(String) onRoleChanged;
  final Function(String) onSearchChanged;
  final Function(StatusFilter) onStatusChanged;
  final VoidCallback onSearch;
  final VoidCallback? onExport;
  final List<String> roleOptions;

  const LoginPermissionFilterBar({
    super.key,
    required this.roleFilter,
    required this.searchQuery,
    required this.statusFilter,
    required this.onRoleChanged,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSearch,
    this.onExport,
    required this.roleOptions,
  });

  @override
  Widget build(BuildContext context) {
    final showRoleDropdown = roleOptions.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Users title
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEAFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  size: 12,
                  color: Color(0xFF6D4AFF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Filter Users'),
                      TextSpan(
                        text: showRoleDropdown
                            ? ' — narrow by sub-role, name, email, or status'
                            : ' — narrow by name, email, or status',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filters row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Stacked layout for narrow screens
                return Column(
                  children: [
                    if (showRoleDropdown) ...[
                      _buildRoleDropdown(),
                      const SizedBox(height: 12),
                    ],
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildStatusDropdown(),
                  ],
                );
              } else {
                // Row layout for wider screens
                return Row(
                  children: [
                    if (showRoleDropdown) ...[
                      Expanded(child: _buildRoleDropdown()),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // Status chips + buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Status chips
              _buildStatusChip(StatusFilter.all),
              _buildStatusChip(StatusFilter.active),
              _buildStatusChip(StatusFilter.disabled),
              _buildStatusChip(StatusFilter.neverLoggedIn),

              const SizedBox(width: 8),

              // Export button
              if (onExport != null)
                OutlinedButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 36),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Search button
              ElevatedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dashboardPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 36),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROLE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        AppDropdown<String>(
          value: roleFilter,
          items: roleOptions
              .map((role) => DropdownMenuItem<String?>(
                    value: role,
                    child: Text(role, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onRoleChanged(value);
          },
          height: 40,
          fontSize: 13,
          textColor: AppColors.textPrimary,
          borderColor: AppColors.cardBorder,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEARCH',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: TextEditingController(text: searchQuery)
              ..selection = TextSelection.collapsed(offset: searchQuery.length),
            onChanged: onSearchChanged,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Name, email, or ID…',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOGIN STATUS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        AppDropdown<StatusFilter>(
          value: statusFilter,
          items: StatusFilter.values
              .map((status) => DropdownMenuItem<StatusFilter?>(
                    value: status,
                    child: Text(
                      status == StatusFilter.all ? 'All statuses' : status.label,
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
          height: 40,
          fontSize: 13,
          textColor: AppColors.textPrimary,
          borderColor: AppColors.cardBorder,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ],
    );
  }

  Widget _buildStatusChip(StatusFilter status) {
    final isActive = statusFilter == status;
    Color? dotColor;

    if (!isActive) {
      switch (status) {
        case StatusFilter.active:
          dotColor = const Color(0xFF10B981);
          break;
        case StatusFilter.disabled:
          dotColor = const Color(0xFFF87171);
          break;
        case StatusFilter.neverLoggedIn:
          dotColor = const Color(0xFFFBBF24);
          break;
        case StatusFilter.all:
          break;
      }
    }

    return GestureDetector(
      onTap: () => onStatusChanged(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.dashboardPurple : null,
          border: Border.all(
            color: isActive ? AppColors.dashboardPurple : AppColors.cardBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              status.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
