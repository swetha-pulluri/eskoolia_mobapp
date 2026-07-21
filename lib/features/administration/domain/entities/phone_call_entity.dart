/// Phone Call Log entry — mirrors backend `PhoneCallLogEntry` /
/// `/api/v1/admissions/phone-call-logs/`.
class PhoneCallEntity {
  final int? id;
  final String name;
  final String phone;
  final String date;
  final String? nextFollowUpDate;
  final String? callDuration;
  final String? description;
  /// 'I' = Incoming, 'O' = Outgoing
  final String callType;
  final String? createdByName;
  final String? createdAt;

  const PhoneCallEntity({
    this.id,
    required this.name,
    required this.phone,
    required this.date,
    this.nextFollowUpDate,
    this.callDuration,
    this.description,
    required this.callType,
    this.createdByName,
    this.createdAt,
  });

  factory PhoneCallEntity.fromJson(Map<String, dynamic> json) {
    return PhoneCallEntity(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      date: json['date'] as String? ?? '',
      nextFollowUpDate: json['next_follow_up_date'] as String?,
      callDuration: json['call_duration']?.toString(),
      description: json['description'] as String?,
      callType: json['call_type'] as String? ?? 'I',
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'date': date,
      if (nextFollowUpDate != null && nextFollowUpDate!.isNotEmpty) 'next_follow_up_date': nextFollowUpDate,
      if (callDuration != null && callDuration!.isNotEmpty) 'call_duration': callDuration,
      if (description != null) 'description': description,
      'call_type': callType,
    };
  }
}
