import 'package:flutter/material.dart';
import '../../domain/models/fees_home_data.dart';

/// Mirrors FeesPaymentsPanel.tsx's "Audit Trail" card. `auditTrail` comes
/// from the (currently non-existent) `/fees/home/` endpoint — see
/// fees_home_data.dart's doc comment — so this renders empty on the real
/// backend today, same as the web app.
class FeesAuditTrailCard extends StatelessWidget {
  final List<FeesAuditItem> auditTrail;

  const FeesAuditTrailCard({super.key, required this.auditTrail});

  static Color _hex(String hex) => Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Audit Trail', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F1222))),
                    SizedBox(height: 4),
                    Text(
                      'Immutable finance events for payment, assignment, concession, and rollover changes.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9197AE), height: 1.5),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFECECF2)),
                ),
                child: const Text('Today', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF0F1222))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < auditTrail.length; i++) _auditRow(auditTrail[i], isFirst: i == 0),
        ],
      ),
    );
  }

  Widget _auditRow(FeesAuditItem item, {required bool isFirst}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isFirst ? null : const Border(top: BorderSide(color: Color(0xFFECECF2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _hex(item.bg), shape: BoxShape.circle),
            child: Text(item.initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.event, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F1222))),
                const SizedBox(height: 3),
                Text(item.desc, style: const TextStyle(fontSize: 13, color: Color(0xFF9197AE), height: 1.45)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item.date, style: const TextStyle(fontSize: 12.5, color: Color(0xFF9197AE))),
        ],
      ),
    );
  }
}
