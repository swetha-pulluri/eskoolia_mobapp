/// InspireHub domain models — competitions, entered results, and the small
/// lookup tables (level/type/position) that drive both the Compose form and
/// the scoring logic.
///
/// Source of truth on web: frontend/components/competitions/*.jsx +
/// backend/apps/competitions/{models,serializers,views}.py. Ported to a
/// single self-contained feature here — see [../inspire_hub_store.dart] for
/// why competitions live primarily in on-device storage rather than the
/// backend.
library;

/// A competition's scope/level. Mirrors backend `Competition.LEVEL_CHOICES`
/// plus web's extra `inter_house` option, which the Django model has no
/// choice for — see [backendValue].
enum CompetitionLevel {
  intraClass('intra_class', 'Intra-Class'),
  interClass('inter_class', 'Inter-Class'),
  intraSchool('intra_school', 'Intra-School'),
  interHouse('inter_house', 'Inter-House'),
  interSchool('inter_school', 'Inter-School'),
  district('district', 'District'),
  state('state', 'State'),
  national('national', 'National'),
  international('international', 'International');

  final String value;
  final String label;
  const CompetitionLevel(this.value, this.label);

  static CompetitionLevel fromValue(String v) => values.firstWhere(
    (e) => e.value == v,
    orElse: () => CompetitionLevel.intraSchool,
  );

  /// The backend has no `inter_house` choice, so an Inter-House event is
  /// filed as Intra-School when syncing to the server. The local draft keeps
  /// its real `inter_house` level regardless — scope detection and the
  /// Dashboard tab both read the local value, only the outgoing create
  /// payload uses this.
  String get backendValue => this == CompetitionLevel.interHouse ? 'intra_school' : value;
}

/// Mirrors backend `Competition.TYPE_CHOICES`.
enum CompetitionType {
  academic('academic', 'Academic', '📚'),
  sports('sports', 'Sports', '🏆'),
  cultural('cultural', 'Cultural', '🎭'),
  arts('arts', 'Arts', '🎨'),
  debate('debate', 'Debate', '🎤'),
  stem('stem', 'STEM', '🔬'),
  other('other', 'Other', '✨');

  final String value;
  final String label;
  final String icon;
  const CompetitionType(this.value, this.label, this.icon);

  static CompetitionType fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => CompetitionType.academic);
}

/// One selectable result position. Values match backend
/// `Result.POSITION_CHOICES` exactly (unlike the web reference, whose UI
/// strings — 'Consolation', 'Participation', 'Not Participated' — don't
/// match the backend's lowercase/underscore choices and would fail Django's
/// ChoiceField validation; using the backend values directly here sidesteps
/// that mismatch entirely rather than reproducing it).
class ResultPositionDef {
  final String value;
  final String short;
  final String icon;
  final int points;
  const ResultPositionDef(this.value, this.short, this.icon, this.points);
}

const kResultPositions = <ResultPositionDef>[
  ResultPositionDef('1st', '1st', '🥇', 10),
  ResultPositionDef('2nd', '2nd', '🥈', 7),
  ResultPositionDef('3rd', '3rd', '🥉', 5),
  ResultPositionDef('consolation', 'Cons.', '🎖', 3),
  ResultPositionDef('participation', 'Part.', '✅', 1),
  ResultPositionDef('not_participated', 'N/P', '🚫', 0),
];

const kPositionLabels = <String, String>{
  '1st': '1st Place',
  '2nd': '2nd Place',
  '3rd': '3rd Place',
  'consolation': 'Consolation',
  'participation': 'Participation',
  'not_participated': 'Not Participated',
};

const kPositionRank = <String, int>{
  '1st': 0,
  '2nd': 1,
  '3rd': 2,
  'consolation': 3,
  'participation': 4,
  'not_participated': 5,
};

/// The podium tier shown in the main results grid; Participation/Not
/// Participated live in the "Other outcomes" section instead so huge
/// rosters don't crowd the grid — mirrors web's `PODIUM_POSITIONS` split.
const kPodiumPositions = <String>{'1st', '2nd', '3rd', 'consolation', ''};

ResultPositionDef? positionDefFor(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final p in kResultPositions) {
    if (p.value == value) return p;
  }
  return null;
}

/// Pre-fill hint for "Personal contribution", by position — mirrors web's
/// SMART_HINTS.
const kSmartHints = <String, String>{
  '1st': 'Demonstrated outstanding mastery and confidence throughout the competition.',
  '2nd': 'Showed strong skill and composure, finishing among the top performers.',
  '3rd': 'Performed with consistent skill, securing a podium finish.',
  'consolation': 'Showed notable spirit and effort that the judges recognised.',
  'participation': 'Took part with enthusiasm and a positive learning attitude.',
  'not_participated': '',
};

class AiMeta {
  final bool cacheHit;
  final bool fallback;
  const AiMeta({this.cacheHit = false, this.fallback = false});

  Map<String, dynamic> toJson() => {'cache_hit': cacheHit, 'fallback': fallback};

  factory AiMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiMeta();
    return AiMeta(cacheHit: json['cache_hit'] == true, fallback: json['fallback'] == true);
  }
}

/// One participant's entry within a [Competition]. Denormalises the
/// student's name/class/house/clubs at the moment they were added, so a
/// competition's results stay meaningful even if the student roster changes
/// later — matches web's embedded `_student` snapshot.
class ResultEntry {
  final int studentId;
  final String studentName;
  final String admissionNo;
  final String className;
  final String sectionName;
  final int? houseId;
  final String? houseName;
  final List<int> clubIds;
  final String position; // '' when unset, else a kResultPositions value
  final int points;
  final String personalContribution;
  final String aiResponse;
  final AiMeta aiMeta;

  const ResultEntry({
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.className,
    required this.sectionName,
    this.houseId,
    this.houseName,
    this.clubIds = const [],
    this.position = '',
    this.points = 0,
    this.personalContribution = '',
    this.aiResponse = '',
    this.aiMeta = const AiMeta(),
  });

  ResultEntry copyWith({
    String? position,
    int? points,
    String? personalContribution,
    String? aiResponse,
    AiMeta? aiMeta,
  }) {
    return ResultEntry(
      studentId: studentId,
      studentName: studentName,
      admissionNo: admissionNo,
      className: className,
      sectionName: sectionName,
      houseId: houseId,
      houseName: houseName,
      clubIds: clubIds,
      position: position ?? this.position,
      points: points ?? this.points,
      personalContribution: personalContribution ?? this.personalContribution,
      aiResponse: aiResponse ?? this.aiResponse,
      aiMeta: aiMeta ?? this.aiMeta,
    );
  }

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'student_name': studentName,
    'admission_no': admissionNo,
    'class_name': className,
    'section_name': sectionName,
    'house_id': houseId,
    'house_name': houseName,
    'club_ids': clubIds,
    'position': position,
    'points': points,
    'personal_contribution': personalContribution,
    'ai_response': aiResponse,
    'ai_meta': aiMeta.toJson(),
  };

  factory ResultEntry.fromJson(Map<String, dynamic> json) {
    return ResultEntry(
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String? ?? '',
      admissionNo: json['admission_no'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      houseId: json['house_id'] as int?,
      houseName: json['house_name'] as String?,
      clubIds: (json['club_ids'] as List<dynamic>? ?? const []).map((e) => e as int).toList(),
      position: json['position'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      personalContribution: json['personal_contribution'] as String? ?? '',
      aiResponse: json['ai_response'] as String? ?? '',
      aiMeta: AiMeta.fromJson(json['ai_meta'] as Map<String, dynamic>?),
    );
  }
}

/// A single InspireHub event — draft or finalised. Persisted on-device (see
/// InspireHubStore); `backendId`/`isLocal` track whether the Django
/// `Competition` row exists so bulk-saving results is possible.
class Competition {
  final String id;
  final int? backendId;
  final bool isLocal;
  final String name;
  final String date; // yyyy-MM-dd
  final CompetitionLevel level;
  final CompetitionType compType;
  final String sportType;
  final String location;
  final String opponent;
  final String notes;
  final int? houseAId;
  final int? houseBId;
  final List<String> classes; // inter_class scope
  final String className; // intra_class scope
  final List<String> sections; // intra_class scope
  final String status; // 'draft' | 'final'
  final List<ResultEntry> results;
  final String createdAt;
  final String updatedAt;
  final String? finalisedAt;

  const Competition({
    required this.id,
    this.backendId,
    this.isLocal = true,
    required this.name,
    required this.date,
    this.level = CompetitionLevel.intraSchool,
    this.compType = CompetitionType.academic,
    this.sportType = '',
    this.location = '',
    this.opponent = '',
    this.notes = '',
    this.houseAId,
    this.houseBId,
    this.classes = const [],
    this.className = '',
    this.sections = const [],
    this.status = 'draft',
    this.results = const [],
    required this.createdAt,
    required this.updatedAt,
    this.finalisedAt,
  });

  bool get isFinal => status == 'final';

  Competition copyWith({
    int? backendId,
    bool? isLocal,
    String? name,
    String? date,
    CompetitionLevel? level,
    CompetitionType? compType,
    String? sportType,
    String? location,
    String? opponent,
    String? notes,
    int? houseAId,
    bool clearHouseA = false,
    int? houseBId,
    bool clearHouseB = false,
    List<String>? classes,
    String? className,
    List<String>? sections,
    String? status,
    List<ResultEntry>? results,
    String? createdAt,
    String? updatedAt,
    String? finalisedAt,
  }) {
    return Competition(
      id: id,
      backendId: backendId ?? this.backendId,
      isLocal: isLocal ?? this.isLocal,
      name: name ?? this.name,
      date: date ?? this.date,
      level: level ?? this.level,
      compType: compType ?? this.compType,
      sportType: sportType ?? this.sportType,
      location: location ?? this.location,
      opponent: opponent ?? this.opponent,
      notes: notes ?? this.notes,
      houseAId: clearHouseA ? null : (houseAId ?? this.houseAId),
      houseBId: clearHouseB ? null : (houseBId ?? this.houseBId),
      classes: classes ?? this.classes,
      className: className ?? this.className,
      sections: sections ?? this.sections,
      status: status ?? this.status,
      results: results ?? this.results,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      finalisedAt: finalisedAt ?? this.finalisedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'backend_id': backendId,
    'is_local': isLocal,
    'name': name,
    'date': date,
    'level': level.value,
    'comp_type': compType.value,
    'sport_type': sportType,
    'location': location,
    'opponent': opponent,
    'notes': notes,
    'house_a_id': houseAId,
    'house_b_id': houseBId,
    'classes': classes,
    'class_name': className,
    'sections': sections,
    'status': status,
    'results': results.map((r) => r.toJson()).toList(),
    'created_at': createdAt,
    'updated_at': updatedAt,
    'finalised_at': finalisedAt,
  };

  factory Competition.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toIso8601String();
    return Competition(
      id: json['id'] as String,
      backendId: json['backend_id'] as int?,
      isLocal: json['is_local'] as bool? ?? true,
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? now.substring(0, 10),
      level: CompetitionLevel.fromValue(json['level'] as String? ?? ''),
      compType: CompetitionType.fromValue(json['comp_type'] as String? ?? ''),
      sportType: json['sport_type'] as String? ?? '',
      location: json['location'] as String? ?? '',
      opponent: json['opponent'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      houseAId: json['house_a_id'] as int?,
      houseBId: json['house_b_id'] as int?,
      classes: (json['classes'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      className: json['class_name'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      status: json['status'] as String? ?? 'draft',
      results: (json['results'] as List<dynamic>? ?? const [])
          .map((e) => ResultEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? now,
      updatedAt: json['updated_at'] as String? ?? now,
      finalisedAt: json['finalised_at'] as String?,
    );
  }
}
