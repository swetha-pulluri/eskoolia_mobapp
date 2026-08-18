import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/child_detail_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';
import '../widgets/sibling_tabs.dart';

const Color _brandPurple = Color(0xFF6D4AFF);
const Color _purpleDeep = Color(0xFF4F35CC);
const Color _ok = Color(0xFF0E9F6E);
const Color _warn = Color(0xFFD97706);
const Color _danger = Color(0xFFDC2626);

/// My Children — mobile port of web's `(parent-portal)/parent/children/page.tsx`.
///
/// This ONE page is also what "Timetable", "Syllabus", "Homework" (under
/// the Academics module) and all of Student Life's sub-nav items resolve to
/// on web — there is no dedicated timetable/syllabus/homework page in the
/// reference app, just this child profile screen (see
/// `parent-routes.ts`: every one of those sub-items' `path` is literally
/// `/parent/children`). So this page's own content — profile, attendance,
/// exam results, behaviour — IS the real "Academics" section; nothing here
/// was invented beyond what web actually ships.
///
/// Mobile simplification: web's 2-column (content + 300px sidebar) grid
/// becomes a single stacked column; the 4-across profile stat grid becomes
/// 2x2 to avoid cramming on narrow phones.
class ChildrenPage extends ConsumerWidget {
  const ChildrenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(parentMeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentMeProvider);
          ref.invalidate(childDetailProvider);
        },
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(error: error, onRetry: () => ref.invalidate(parentMeProvider)),
          data: (me) => _ChildrenContent(me: me),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _LoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 32, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text('Could not load your children', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                  const SizedBox(height: 6),
                  Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildrenContent extends ConsumerWidget {
  final ParentMeEntity me;
  const _ChildrenContent({required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedChildProvider);
    final detailAsync = ref.watch(childDetailProvider);
    final detail = detailAsync.valueOrNull;
    final detailLoading = detailAsync.isLoading;
    final detailError = detailAsync.hasError;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(childrenCount: me.children.length),
          if (me.children.length > 1) ...[
            const SizedBox(height: 12),
            SiblingTabs(children: me.children, selectedId: selected?.id),
          ],
          if (detailError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(10)),
              child: const Text('Could not load child data. Pull to refresh.', style: TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C))),
            ),
          ],
          if (me.children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: Text(
                    'No active children linked to your account. Contact the school administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.ink3),
                  ),
                ),
              ),
            )
          else if (detailLoading && detail == null)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (detail != null) ...[
            const SizedBox(height: 14),
            _ProfileCard(detail: detail),
            const SizedBox(height: 12),
            _AttendanceCard(detail: detail),
            const SizedBox(height: 12),
            _ExamResultsCard(marks: detail.recentMarks),
            const SizedBox(height: 12),
            _BehaviourCard(points: detail.behaviourPoints),
            if (detail.attendance.total > 0) ...[
              const SizedBox(height: 12),
              _AttendanceGlanceCard(att: detail.attendance),
            ],
            const SizedBox(height: 12),
            _QuickActionsCard(),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int childrenCount;
  const _Header({required this.childrenCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.ink1, fontWeight: FontWeight.w600),
                  children: const [
                    TextSpan(text: 'My '),
                    TextSpan(text: 'Children', style: TextStyle(color: _brandPurple, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'View attendance, results, and profile details for each child.',
                style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.4),
              ),
            ],
          ),
        ),
        if (childrenCount > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), color: AppColors.bg2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 13, color: AppColors.ink3),
                const SizedBox(width: 5),
                Text('$childrenCount ${childrenCount == 1 ? 'child' : 'children'}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ChildDetailEntity detail;
  const _ProfileCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final initials = detail.name.split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
    final dob = detail.dateOfBirth != null ? DateTime.tryParse(detail.dateOfBirth!) : null;

    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_brandPurple, _purpleDeep], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: (detail.photoUrl != null && detail.photoUrl!.isNotEmpty) ? NetworkImage(detail.photoUrl!) : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: (detail.photoUrl == null || detail.photoUrl!.isEmpty)
                      ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(detail.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        [
                          [detail.className, detail.sectionName].where((s) => s.isNotEmpty).join(' · '),
                          if ((detail.rollNo ?? '').isNotEmpty) 'Roll ${detail.rollNo}',
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.78)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _statGrid([
            _ProfileStat(Icons.tag_outlined, 'Admission No.', detail.admissionNo?.isNotEmpty == true ? detail.admissionNo! : '—'),
            _ProfileStat(Icons.person_outline, 'Gender', detail.gender?.isNotEmpty == true ? '${detail.gender![0].toUpperCase()}${detail.gender!.substring(1)}' : '—'),
            _ProfileStat(Icons.cake_outlined, 'Date of Birth', dob != null ? DateFormat('d MMM yyyy').format(dob) : '—'),
            _ProfileStat(Icons.water_drop_outlined, 'Blood Group', detail.bloodGroup?.isNotEmpty == true ? detail.bloodGroup! : '—'),
          ]),
        ],
      ),
    );
  }

  Widget _statGrid(List<_ProfileStat> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      children: [for (final s in stats) _statCell(s)],
    );
  }

  Widget _statCell(_ProfileStat s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border), left: BorderSide(color: AppColors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(s.icon, size: 10, color: AppColors.ink3),
              const SizedBox(width: 4),
              Text(s.label, style: const TextStyle(fontSize: 9.5, color: AppColors.ink3)),
            ],
          ),
          const SizedBox(height: 2),
          Text(s.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink1), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ProfileStat {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileStat(this.icon, this.label, this.value);
}

class _AttendanceCard extends StatelessWidget {
  final ChildDetailEntity detail;
  const _AttendanceCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final att = detail.attendance;
    final pct = att.pct;

    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: const Color(0xFFEEEAFF), borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.calendar_month_outlined, size: 13, color: _brandPurple),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Attendance — Last 90 Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                ),
                if (att.total > 0) Text('${att.total} days', style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: pct == null
                ? const SizedBox(height: 30, child: Center(child: Text('No records', style: TextStyle(fontSize: 12, color: AppColors.ink3))))
                : Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _Ring(pct: pct),
                          const SizedBox(width: 18),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              childAspectRatio: 2.6,
                              children: [
                                _miniStat('Present', att.present, _ok),
                                _miniStat('Absent', att.absent, _danger),
                                _miniStat('Late', att.late, _warn),
                                _miniStat('Half Day', att.halfDay, _brandPurple),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (att.total > 0) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: (pct / 100).clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(pct >= 85 ? _ok : (pct >= 70 ? _warn : _danger)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            pct >= 85 ? '✓ Good standing' : (pct >= 70 ? '⚠ Below recommended 85%' : '⚠ Critical — please follow up'),
                            style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.ink3)),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  final double pct;
  const _Ring({required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 85 ? _ok : (pct >= 70 ? _warn : _danger);
    return SizedBox(
      width: 84,
      height: 84,
      child: CustomPaint(
        painter: _RingPainter(pct: pct.clamp(0, 100), color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              const Text('Attendance', style: TextStyle(fontSize: 9, color: AppColors.ink3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color color;
  const _RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 7) / 2;
    const stroke = 7.0;

    final track = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    if (pct > 0) {
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * (pct / 100);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}

class _ExamResultsCard extends StatelessWidget {
  final List<ExamMarkEntity> marks;
  const _ExamResultsCard({required this.marks});

  @override
  Widget build(BuildContext context) {
    final byTerm = <String, List<ExamMarkEntity>>{};
    for (final m in marks) {
      final key = m.term.isNotEmpty ? m.term : '—';
      byTerm.putIfAbsent(key, () => []).add(m);
    }

    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Row(
              children: [
                _SectionIcon(icon: Icons.menu_book_outlined),
                SizedBox(width: 8),
                Text('Exam Results', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: marks.isEmpty
                ? const SizedBox(
                    height: 40,
                    child: Center(child: Text('No exam records yet.', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in byTerm.entries) ...[
                        if (entry.key != byTerm.keys.first) const SizedBox(height: 16),
                        Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.6)),
                        const SizedBox(height: 7),
                        _MarksTable(rows: entry.value),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MarksTable extends StatelessWidget {
  final List<ExamMarkEntity> rows;
  const _MarksTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ink2);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.bg2,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Subject', style: headerStyle)),
                Expanded(flex: 3, child: Text('Exam', style: headerStyle)),
                Expanded(flex: 2, child: Text('Obt.', style: headerStyle, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Max', style: headerStyle, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('%', style: headerStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) _row(rows[i], i < rows.length - 1),
        ],
      ),
    );
  }

  Widget _row(ExamMarkEntity m, bool showDivider) {
    final pct = m.fullMarks > 0 ? (m.obtained / m.fullMarks * 100).round() : 0;
    final passed = !m.absent && m.obtained >= m.passMarks;
    final color = m.absent ? AppColors.ink3 : (passed ? _ok : _danger);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(m.subject.isNotEmpty ? m.subject : '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink1), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(m.examName.isNotEmpty ? m.examName : '—', style: const TextStyle(fontSize: 11, color: AppColors.ink3), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(m.absent ? 'Abs' : m.obtained.toStringAsFixed(0), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: color))),
          Expanded(flex: 2, child: Text(m.fullMarks.toStringAsFixed(0), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.ink3))),
          Expanded(flex: 2, child: Text(m.absent ? '—' : '$pct%', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
        ],
      ),
    );
  }
}

class _BehaviourCard extends StatelessWidget {
  final int points;
  const _BehaviourCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final positive = points >= 0;
    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Row(
              children: [
                _SectionIcon(icon: Icons.emoji_events_outlined),
                SizedBox(width: 8),
                Text('Behaviour Points', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: positive ? const Color(0xFFEEEAFF) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: Text(
                    '${positive ? '+' : ''}$points',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: positive ? _brandPurple : _danger),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    points > 0 ? 'Positive record — keep it up!' : (points < 0 ? 'Needs improvement. Talk to the class teacher.' : 'No behaviour records yet.'),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.ink3, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Attendance at a glance" — web's compact right-sidebar summary, distinct
/// from the fuller `_AttendanceCard` ring above it: just the overall rate,
/// a progress bar, and a 2x2 Present/Absent/Late/Total grid. Only shown
/// when there's at least one recorded school day, matching web's own
/// `att && att.total > 0` guard.
class _AttendanceGlanceCard extends StatelessWidget {
  final AttendanceSummaryEntity att;
  const _AttendanceGlanceCard({required this.att});

  @override
  Widget build(BuildContext context) {
    final pct = att.pct ?? 0;
    final color = pct >= 85 ? _ok : _danger;

    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ATTENDANCE AT A GLANCE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.6)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall rate', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
                Text('$pct%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                minHeight: 5,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: [
                _glanceStat('Present', att.present, _ok),
                _glanceStat('Absent', att.absent, _danger),
                _glanceStat('Late', att.late, _warn),
                _glanceStat('Total', att.total, AppColors.ink2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _glanceStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Text('QUICK ACTIONS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.6)),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Real page now — matches the same route the Attendance module's
          // top-nav pill and Home screen's "Attendance"/"Apply Leave" tiles
          // already navigate to.
          _actionRow(context, Icons.calendar_month_outlined, 'Attendance Calendar', 'View month-wise', _ok, const Color(0x1A22C55E), onTap: () => context.go('/parent/attendance')),
          _actionRow(context, Icons.credit_card_outlined, 'Fee Summary', 'Dues & payments', _warn, const Color(0xFFFFF7ED), onTap: () => context.go('/parent/fees')),
          _actionRow(context, Icons.notifications_outlined, 'Notices', 'School circulars', const Color(0xFF0284C7), const Color(0xFFF0F9FF), onTap: () => context.go('/parent/notices')),
          _actionRow(context, Icons.menu_book_outlined, 'All Results', 'Exam reports', _brandPurple, const Color(0xFFEEEAFF), onTap: () => context.showSnackBar('All Results - Coming Soon'), showDivider: false),
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context, IconData icon, String label, String sublabel, Color color, Color bg, {required VoidCallback onTap, bool showDivider = true}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink1)),
                  Text(sublabel, style: const TextStyle(fontSize: 10.5, color: AppColors.ink3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  const _SectionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: const Color(0xFFEEEAFF), borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Icon(icon, size: 13, color: _brandPurple),
    );
  }
}
