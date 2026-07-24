// Audit Log tab — port of AuditLogTab from
// components/academics/StaffAssignmentPanels.tsx.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/staff_assignment_entities.dart';
import '../../providers/academics_providers.dart';

class StaffAuditLogTab extends ConsumerStatefulWidget {
  const StaffAuditLogTab({super.key});

  @override
  ConsumerState<StaffAuditLogTab> createState() => _StaffAuditLogTabState();
}

class _StaffAuditLogTabState extends ConsumerState<StaffAuditLogTab> {
  List<StaffAuditLogEntry> _logs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(academicsRepositoryProvider).fetchStaffAuditLog();
      if (mounted) setState(() => _logs = data);
    } catch (_) {
      // best-effort — matches the reference's silent .catch(() => {})
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year}, $h:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 64), child: Center(child: Text('Loading audit log…', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))));
    }
    if (_logs.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 64), child: Center(child: Text('No audit records yet. CT changes will appear here.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))));
    }

    const colClass = 170.0, colOld = 130.0, colNew = 130.0, colReason = 180.0, colBy = 130.0, colDate = 150.0;
    const tableWidth = colClass + colOld + colNew + colReason + colBy + colDate + 32; // + row horizontal padding (16 * 2)

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: staffLine), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))]),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
              child: Row(children: [
                SizedBox(width: colClass, child: _header('Class / Section')),
                SizedBox(width: colOld, child: _header('Old Teacher')),
                SizedBox(width: colNew, child: _header('New Teacher')),
                SizedBox(width: colReason, child: _header('Reason')),
                SizedBox(width: colBy, child: _header('Changed By')),
                SizedBox(width: colDate, child: _header('Date')),
              ]),
            ),
            for (final log in _logs)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFFAFAFA)))),
                child: Row(children: [
                  SizedBox(width: colClass, child: Text('${log.className} — ${log.sectionName}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
                  SizedBox(width: colOld, child: Text(log.oldTeacherName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
                  SizedBox(width: colNew, child: Text(log.newTeacherName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)))),
                  SizedBox(width: colReason, child: Text(log.reason, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
                  SizedBox(width: colBy, child: Text(log.changedByName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
                  SizedBox(width: colDate, child: Text(_formatDate(log.changedAt), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _header(String text) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.3));
}
