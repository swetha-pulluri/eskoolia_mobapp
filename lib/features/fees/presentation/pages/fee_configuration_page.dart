import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../student/domain/models/academic_year.dart';
import '../../../student/domain/models/school_class.dart';
import '../providers/fees_config_providers.dart';
import '../widgets/concession_rules_tab.dart';
import '../widgets/fee_config_help_modal.dart';
import '../widgets/fee_groups_tab.dart';
import '../widgets/fee_schedules_tab.dart';
import '../widgets/fee_types_tab.dart';
import '../widgets/fee_config_styles.dart';
import '../widgets/fees_layout.dart';
import '../widgets/late_fee_rules_tab.dart';

enum _Tab { feeGroups, feeTypes, feeSchedules, concessionRules, lateFeeRules }

const _tabLabels = {
  _Tab.feeGroups: 'Fee Groups',
  _Tab.feeTypes: 'Fee Types',
  _Tab.feeSchedules: 'Fee Schedules',
  _Tab.concessionRules: 'Concession Rules',
  _Tab.lateFeeRules: 'Late Fee Rules',
};

/// Fee Configuration — converted from
/// `frontend/components/fees/FeeConfigurationPanel.tsx` (the "Fee
/// Configuration" tab of the Fees module, `/fees/configuration`).
///
/// Owns only what the source genuinely shares across every tab at the
/// top level: the academic year list/selection and the class list (both
/// loaded once on mount). Everything else (fee groups, fee types, term
/// settings, schedules, concession/late-fee rules) is fetched by each tab
/// independently, matching the source's own per-tab-visit `useEffect`
/// refetches.
class FeeConfigurationPage extends ConsumerStatefulWidget {
  const FeeConfigurationPage({super.key});

  @override
  ConsumerState<FeeConfigurationPage> createState() => _FeeConfigurationPageState();
}

class _FeeConfigurationPageState extends ConsumerState<FeeConfigurationPage> {
  _Tab _activeTab = _Tab.feeGroups;
  List<AcademicYear> _academicYears = [];
  int? _academicYearId;
  List<SchoolClass> _availableClasses = [];

  String? _toast;

  @override
  void initState() {
    super.initState();
    _loadAcademicYears();
    _loadClasses();
  }

  Future<void> _loadAcademicYears() async {
    try {
      final years = await ref.read(feesConfigRepositoryProvider).fetchAcademicYears();
      if (!mounted) return;
      final current = years.where((y) => y.isCurrent).firstOrNull ?? years.firstOrNull;
      setState(() {
        _academicYears = years;
        _academicYearId = current?.id;
      });
    } catch (_) {
      if (mounted) _showToast('Unable to load academic years.');
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await ref.read(feesConfigRepositoryProvider).fetchClasses();
      if (mounted) setState(() => _availableClasses = classes);
    } catch (_) {
      if (mounted) _showToast('Unable to load classes.');
    }
  }

  void _showToast(String message) {
    setState(() => _toast = message);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted && _toast == message) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeesLayout(
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTabBar(),
                  const SizedBox(height: 20),
                  _buildTabContent(),
                ],
              ),
            ),
            if (_toast != null)
              Positioned(
                top: 12,
                right: 12,
                child: _ToastBubble(message: _toast!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Its own card — same white/gray-bordered style already used by every
    // tab below it (via `FeeConfigCard`) and by the Fees Home header —
    // instead of floating text directly on the page background.
    return FeeConfigCard(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('CONFIGURABLE FEE ENGINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Color(0xFF6D4AFF))),
              SizedBox(height: 6),
              Text('Fee Configuration', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF0F1222), height: 1.1)),
              SizedBox(height: 8),
              Text(
                'Create groups, fee types, schedules, concessions, and late fee rules without hardcoded school assumptions.',
                style: TextStyle(fontSize: 14, color: Color(0xFF9197AE), height: 1.5),
              ),
            ],
          ),
          SizedBox(
            height: 40,
            child: Material(
              color: const Color(0xFF6D4AFF),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => _showToast('Configuration saved successfully.'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text('Save Configuration', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in _Tab.values) ...[
            _tabPill(tab),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _tabPill(_Tab tab) {
    final isActive = tab == _activeTab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6D4AFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: const Color(0xFFE8E8EE)),
          boxShadow: isActive ? const [BoxShadow(color: Color(0x386D4AFF), blurRadius: 8, offset: Offset(0, 2))] : null,
        ),
        child: Text(
          _tabLabels[tab]!,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFF5B5E72)),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case _Tab.feeGroups:
        return FeeGroupsTab(
          academicYearId: _academicYearId,
          academicYears: _academicYears,
          availableClasses: _availableClasses,
          onToast: _showToast,
        );
      case _Tab.feeTypes:
        return FeeTypesTab(academicYearId: _academicYearId, onToast: _showToast);
      case _Tab.feeSchedules:
        return FeeSchedulesTab(
          academicYearId: _academicYearId,
          academicYears: _academicYears,
          onToast: _showToast,
          onOpenHelp: () => showDialog(context: context, builder: (_) => const FeeConfigHelpModal()),
        );
      case _Tab.concessionRules:
        return ConcessionRulesTab(onToast: _showToast);
      case _Tab.lateFeeRules:
        return LateFeeRulesTab(onToast: _showToast);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ToastBubble extends StatelessWidget {
  final String message;
  const _ToastBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 28, offset: Offset(0, 8))],
        ),
        child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
      ),
    );
  }
}
