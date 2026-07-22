import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/kpi_data.dart';
import '../widgets/kpi_card.dart';
import '../widgets/quick_action_button.dart';

/// School Overview Page
/// Pixel-perfect Flutter recreation of frontend/app/(dashboard)/dashboard/page.tsx
///
/// Displays live KPIs and key metrics across all school operations:
/// - Total Students
/// - Today's Attendance
/// - Fees Collected MTD
/// - Open Admissions
/// - Total Staff
/// - Library Books
/// - Pending Homework
/// - Exams This Week
///
/// Plus Quick Actions for common tasks.
class SchoolOverviewPage extends StatefulWidget {
  const SchoolOverviewPage({super.key});

  @override
  State<SchoolOverviewPage> createState() => _SchoolOverviewPageState();
}

class _SchoolOverviewPageState extends State<SchoolOverviewPage> {
  bool _isLoading = true;
  late KpiData _kpiData;

  @override
  void initState() {
    super.initState();
    _loadKPIs();
  }

  Future<void> _loadKPIs() async {
    // Simulate API call with delay
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Replace with actual API call when backend is connected
    // final response = await dashboardRepository.getKPIs();
    // setState(() {
    //   _kpiData = KpiData.fromJson(response);
    //   _isLoading = false;
    // });

    if (mounted) {
      setState(() {
        _kpiData = KpiData.mock();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              _buildKPISection(),
              _buildQuickActionsSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.cardBackground,
        child: Column(
          children: [
            // Breadcrumb
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF9197AE), // ink-3
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 11,
                    color: const Color(0xFF9197AE).withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF9197AE), // ink-3
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 11,
                    color: const Color(0xFF9197AE).withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'School Overview',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF5A607A), // ink-2
                    ),
                  ),
                ],
              ),
            ),

            // Title + Description
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with accent
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.7,
                        color: Color(0xFF0F1222), // ink-1
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(text: 'School '),
                        TextSpan(
                          text: 'Overview',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF6D4AFF), // purple
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  const Text(
                    'Live KPIs and key metrics across all school operations',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A607A), // ink-2
                    ),
                  ),
                ],
              ),
            ),

            // Bottom border
            Container(height: 1, color: AppColors.cardBorder),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KPI SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildKPISection() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid based on screen width
          final screenWidth = constraints.crossAxisExtent;
          int crossAxisCount;
          double childAspectRatio;

          if (screenWidth < 360) {
            // Very small phones
            // Card height needs ~125px for content
            crossAxisCount = 1;
            childAspectRatio = 2.1;
          } else if (screenWidth < 500) {
            // Small phones
            // Card width ~169px, needs ~130px height
            crossAxisCount = 2;
            childAspectRatio = 1.2;
          } else if (screenWidth < 700) {
            // Medium phones / small tablets
            // Card width ~269px, needs ~130px height
            crossAxisCount = 2;
            childAspectRatio = 1.95;
          } else {
            // Large tablets
            // Card width ~241px, needs ~130px height
            crossAxisCount = 3;
            childAspectRatio = 1.75;
          }

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (_isLoading) {
                return const KpiCardSkeleton();
              }

              final cards = _buildKPICards();
              return cards[index];
            }, childCount: 8),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KPI CARDS DATA
  // ══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildKPICards() {
    return [
      // Total Students
      KpiCard(
        label: 'Total Students',
        value: _kpiData.totalStudents != null
            ? _kpiData.totalStudents.toString()
            : '—',
        delta: 'enrolled this year',
        deltaUp: true,
        icon: Icons.people_rounded,
        iconColor: AppColors.kpiStudentsIcon,
        backgroundColor: AppColors.kpiStudentsBg,
      ),

      // Today's Attendance
      KpiCard(
        label: "Today's Attendance",
        value: _kpiData.attendanceToday ?? '—',
        delta: 'vs yesterday',
        deltaUp: true,
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.kpiAttendanceIcon,
        backgroundColor: AppColors.kpiAttendanceBg,
      ),

      // Fees Collected MTD
      KpiCard(
        label: 'Fees Collected MTD',
        value: _kpiData.feesCollectedMtd ?? '—',
        delta: 'of monthly target',
        deltaUp: true,
        icon: Icons.credit_card_rounded,
        iconColor: AppColors.kpiFeesIcon,
        backgroundColor: AppColors.kpiFeesBg,
      ),

      // Open Admissions
      KpiCard(
        label: 'Open Admissions',
        value: _kpiData.openAdmissions != null
            ? _kpiData.openAdmissions.toString()
            : '—',
        delta: 'awaiting review',
        deltaUp: false,
        icon: Icons.person_add_rounded,
        iconColor: AppColors.kpiAdmissionsIcon,
        backgroundColor: AppColors.kpiAdmissionsBg,
      ),

      // Total Staff
      KpiCard(
        label: 'Total Staff',
        value: _kpiData.totalStaff != null
            ? _kpiData.totalStaff.toString()
            : '—',
        delta: 'active staff members',
        deltaUp: true,
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.kpiStaffIcon,
        backgroundColor: AppColors.kpiStaffBg,
      ),

      // Library Books
      KpiCard(
        label: 'Library Books',
        value: _kpiData.libraryBooks != null
            ? _kpiData.libraryBooks.toString()
            : '—',
        delta: 'in collection',
        deltaUp: true,
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.kpiLibraryIcon,
        backgroundColor: AppColors.kpiLibraryBg,
      ),

      // Pending Homework
      KpiCard(
        label: 'Pending Homework',
        value: _kpiData.pendingHomework != null
            ? _kpiData.pendingHomework.toString()
            : '—',
        delta: 'to be evaluated',
        deltaUp: false,
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.kpiHomeworkIcon,
        backgroundColor: AppColors.kpiHomeworkBg,
      ),

      // Exams This Week
      KpiCard(
        label: 'Exams This Week',
        value: _kpiData.examsThisWeek != null
            ? _kpiData.examsThisWeek.toString()
            : '—',
        delta: 'scheduled',
        deltaUp: true,
        icon: Icons.schedule_rounded,
        iconColor: AppColors.kpiExamsIcon,
        backgroundColor: AppColors.kpiExamsBg,
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9197AE), // ink-3
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Responsive wrap for quick action buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                QuickActionButton(
                  label: 'Mark Attendance',
                  color: AppColors.quickActionAttendance,
                  backgroundColor: AppColors.quickActionAttendanceBg,
                  onTap: () {
                    // TODO: Navigate to attendance screen
                    debugPrint('Navigate to Mark Attendance');
                  },
                ),
                QuickActionButton(
                  label: 'Collect Fees',
                  color: AppColors.quickActionFees,
                  backgroundColor: AppColors.quickActionFeesBg,
                  onTap: () {
                    // TODO: Navigate to fees screen
                    debugPrint('Navigate to Collect Fees');
                  },
                ),
                QuickActionButton(
                  label: 'Add Student',
                  color: AppColors.quickActionStudent,
                  backgroundColor: AppColors.quickActionStudentBg,
                  onTap: () => context.push('/students/enroll'),
                ),
                QuickActionButton(
                  label: 'Exam Schedule',
                  color: AppColors.quickActionExam,
                  backgroundColor: AppColors.quickActionExamBg,
                  onTap: () {
                    // TODO: Navigate to exam schedule screen
                    debugPrint('Navigate to Exam Schedule');
                  },
                ),
                QuickActionButton(
                  label: 'Staff Payroll',
                  color: AppColors.quickActionPayroll,
                  backgroundColor: AppColors.quickActionPayrollBg,
                  onTap: () {
                    // TODO: Navigate to payroll screen
                    debugPrint('Navigate to Staff Payroll');
                  },
                ),
                QuickActionButton(
                  label: 'Library Issues',
                  color: AppColors.quickActionLibrary,
                  backgroundColor: AppColors.quickActionLibraryBg,
                  onTap: () {
                    // TODO: Navigate to library screen
                    debugPrint('Navigate to Library Issues');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
