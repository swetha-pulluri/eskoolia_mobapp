/// Postal Received entry — mirrors backend `PostalReceiveEntry` /
/// `/api/v1/admissions/postal-receive/`.
class PostalReceiveEntity {
  final int? id;
  final String fromTitle;
  final String referenceNo;
  final String address;
  final String? note;
  final String toTitle;
  final String date;
  final String? fileUrl;
  final String? createdByName;

  const PostalReceiveEntity({
    this.id,
    required this.fromTitle,
    required this.referenceNo,
    required this.address,
    this.note,
    required this.toTitle,
    required this.date,
    this.fileUrl,
    this.createdByName,
  });

  factory PostalReceiveEntity.fromJson(Map<String, dynamic> json) {
    return PostalReceiveEntity(
      id: json['id'] as int?,
      fromTitle: json['from_title'] as String? ?? '',
      referenceNo: json['reference_no'] as String? ?? '',
      address: json['address'] as String? ?? '',
      note: json['note'] as String?,
      toTitle: json['to_title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      createdByName: json['created_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'from_title': fromTitle,
        'reference_no': referenceNo,
        'address': address,
        if (note != null) 'note': note,
        'to_title': toTitle,
        'date': date,
      };
}

/// Postal Dispatched entry — mirrors backend `PostalDispatchEntry` /
/// `/api/v1/admissions/postal-dispatch/`.
class PostalDispatchEntity {
  final int? id;
  final String toTitle;
  final String referenceNo;
  final String address;
  final String? note;
  final String fromTitle;
  final String date;
  final String? fileUrl;
  final String? createdByName;

  const PostalDispatchEntity({
    this.id,
    required this.toTitle,
    required this.referenceNo,
    required this.address,
    this.note,
    required this.fromTitle,
    required this.date,
    this.fileUrl,
    this.createdByName,
  });

  factory PostalDispatchEntity.fromJson(Map<String, dynamic> json) {
    return PostalDispatchEntity(
      id: json['id'] as int?,
      toTitle: json['to_title'] as String? ?? '',
      referenceNo: json['reference_no'] as String? ?? '',
      address: json['address'] as String? ?? '',
      note: json['note'] as String?,
      fromTitle: json['from_title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      createdByName: json['created_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'to_title': toTitle,
        'reference_no': referenceNo,
        'address': address,
        if (note != null) 'note': note,
        'from_title': fromTitle,
        'date': date,
      };
}
