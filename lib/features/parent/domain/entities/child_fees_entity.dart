/// Mirrors `ChildFeesView`'s real response (`GET /api/v1/parent/fees/`) —
/// fee assignments for one child, grouped by fees group. See web's
/// `lib/api/parent.ts`'s `ChildFees`.
class ChildFeesEntity {
  final int childId;
  final String childName;
  final FeesSummaryEntity summary;
  final List<FeeGroupEntity> groups;

  const ChildFeesEntity({
    required this.childId,
    required this.childName,
    required this.summary,
    this.groups = const [],
  });

  factory ChildFeesEntity.fromJson(Map<String, dynamic> json) => ChildFeesEntity(
        childId: json['child_id'] as int? ?? 0,
        childName: (json['child_name'] as String?) ?? '',
        summary: json['summary'] != null
            ? FeesSummaryEntity.fromJson(json['summary'] as Map<String, dynamic>)
            : const FeesSummaryEntity(totalBilled: 0, totalPaid: 0, totalDue: 0),
        groups: ((json['groups'] as List?) ?? const [])
            .map((e) => FeeGroupEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Flattened items across every group, matching web's
  /// `data.groups.flatMap(g => g.items)` (used by the Fee Status widget).
  List<FeeItemEntity> get allItems => groups.expand((g) => g.items).toList();
}

class FeesSummaryEntity {
  final double totalBilled;
  final double totalPaid;
  final double totalDue;

  const FeesSummaryEntity({required this.totalBilled, required this.totalPaid, required this.totalDue});

  factory FeesSummaryEntity.fromJson(Map<String, dynamic> json) => FeesSummaryEntity(
        totalBilled: (json['total_billed'] as num?)?.toDouble() ?? 0,
        totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
        totalDue: (json['total_due'] as num?)?.toDouble() ?? 0,
      );
}

class FeeGroupEntity {
  final String groupName;
  final List<FeeItemEntity> items;

  const FeeGroupEntity({required this.groupName, this.items = const []});

  factory FeeGroupEntity.fromJson(Map<String, dynamic> json) => FeeGroupEntity(
        groupName: (json['group_name'] as String?) ?? '',
        items: ((json['items'] as List?) ?? const [])
            .map((e) => FeeItemEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// `status` is one of 'unpaid' | 'partial' | 'paid', matching
/// `apps.fees.models.FeeAssignment.status` verbatim.
class FeeItemEntity {
  final int id;
  final String feeName;
  final double amount;
  final double discount;
  final double netAmount;
  final double paidAmount;
  final double dueAmount;
  final String dueDate;
  final String status;

  const FeeItemEntity({
    required this.id,
    required this.feeName,
    required this.amount,
    required this.discount,
    required this.netAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.dueDate,
    required this.status,
  });

  factory FeeItemEntity.fromJson(Map<String, dynamic> json) => FeeItemEntity(
        id: json['id'] as int,
        feeName: (json['fee_name'] as String?) ?? '—',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
        dueAmount: (json['due_amount'] as num?)?.toDouble() ?? 0,
        dueDate: (json['due_date'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'unpaid',
      );
}
