import '../../../data/local/shared_prefs.dart';
import 'models/competition.dart';

/// House/club/student leaderboard entry — see [InspireHubAggregates].
class LeaderboardEntry {
  final int? id;
  final String name;
  final int points;
  final int wins;
  final String? className;
  const LeaderboardEntry({this.id, required this.name, required this.points, required this.wins, this.className});
}

class RecentWin {
  final String event;
  final String date;
  final String position;
  final String student;
  final String className;
  final String compType;
  const RecentWin({
    required this.event,
    required this.date,
    required this.position,
    required this.student,
    required this.className,
    required this.compType,
  });
}

class InspireHubAggregates {
  final List<Competition> events;
  final int eventCount;
  final int participantCount;
  final int reviewCount;
  final List<LeaderboardEntry> houses;
  final List<LeaderboardEntry> students;
  final List<LeaderboardEntry> groups;
  final List<RecentWin> recent;
  final List<int> monthly; // 12 entries, Jan..Dec

  const InspireHubAggregates({
    required this.events,
    required this.eventCount,
    required this.participantCount,
    required this.reviewCount,
    required this.houses,
    required this.students,
    required this.groups,
    required this.recent,
    required this.monthly,
  });
}

/// InspireHub's persistence layer — a small on-device CRUD store, exactly
/// like web's `inspireHubStore.js` (a localStorage-backed draft/history
/// layer). Competitions and their results live here first; syncing a
/// competition row (and, explicitly via "Save to server", its results) to
/// the real Django backend is a secondary, best-effort step — see
/// [../../data/repositories/competitions_repository_impl.dart]. This keeps
/// InspireHub fully usable offline and matches the reference's own
/// behaviour (its Dashboard/History tabs read only from localStorage, never
/// from the backend).
class InspireHubStore {
  static const _key = 'inspirehub_competitions_v1';
  final SharedPrefs _prefs = SharedPrefs();

  List<Competition> _read() {
    final rows = _prefs.getJsonList(_key) ?? const [];
    final out = <Competition>[];
    for (final row in rows) {
      try {
        out.add(Competition.fromJson(row));
      } catch (_) {
        // Skip a corrupted row rather than losing the whole list.
      }
    }
    return out;
  }

  Future<void> _write(List<Competition> rows) => _prefs.setJsonList(_key, rows.map((c) => c.toJson()).toList());

  List<Competition> list({String? status}) {
    final rows = _read().where((r) => status == null || r.status == status).toList();
    rows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return rows;
  }

  Competition? get(String id) {
    for (final row in _read()) {
      if (row.id == id) return row;
    }
    return null;
  }

  Future<Competition> saveDraft(Competition comp) async {
    final rows = _read();
    final now = DateTime.now().toIso8601String();
    final idx = rows.indexWhere((r) => r.id == comp.id);
    if (idx >= 0) {
      rows[idx] = comp.copyWith(name: titleCaseInspireHub(comp.name), updatedAt: now);
    } else {
      rows.insert(0, comp.copyWith(name: titleCaseInspireHub(comp.name), createdAt: now, updatedAt: now));
    }
    await _write(rows);
    return rows.firstWhere((r) => r.id == comp.id);
  }

  Future<Competition> finalize(Competition comp) async {
    final saved = await saveDraft(comp.copyWith(status: 'final'));
    final finalised = saved.copyWith(finalisedAt: DateTime.now().toIso8601String());
    final rows = _read();
    final idx = rows.indexWhere((r) => r.id == finalised.id);
    if (idx >= 0) {
      rows[idx] = finalised;
      await _write(rows);
    }
    return finalised;
  }

  Future<void> remove(String id) async {
    await _write(_read().where((r) => r.id != id).toList());
  }

  /// House/student/club leaderboards, KPIs, recent wins, and a monthly
  /// activity count — computed from finalised events only. Mirrors web's
  /// `aggregates()`, adapted for this app's real M2M club membership (a
  /// student can be in more than one club, so points fan out to every club
  /// they belong to, rather than assuming a single club per result).
  InspireHubAggregates aggregates({int? year}) {
    final events = list(status: 'final').where((c) {
      if (year == null) return true;
      final d = DateTime.tryParse(c.date);
      return d != null && d.year == year;
    }).toList();

    final housePoints = <String, LeaderboardEntry>{};
    final studentTotals = <String, LeaderboardEntry>{};
    final groupTotals = <String, LeaderboardEntry>{};
    final recent = <RecentWin>[];
    final monthly = List<int>.filled(12, 0);

    for (final c in events) {
      final d = DateTime.tryParse(c.date) ?? DateTime.tryParse(c.updatedAt) ?? DateTime.now();
      monthly[d.month - 1] += 1;

      for (final r in c.results) {
        final pts = r.points;
        if (pts <= 0) continue;

        if (r.houseId != null || (r.houseName ?? '').isNotEmpty) {
          final key = (r.houseId ?? r.houseName).toString();
          final existing = housePoints[key];
          housePoints[key] = LeaderboardEntry(
            id: r.houseId,
            name: r.houseName ?? 'House',
            points: (existing?.points ?? 0) + pts,
            wins: (existing?.wins ?? 0) + (r.position == '1st' ? 1 : 0),
          );
        }

        final sKey = r.studentId.toString();
        final existingS = studentTotals[sKey];
        studentTotals[sKey] = LeaderboardEntry(
          id: r.studentId,
          name: r.studentName.isNotEmpty ? r.studentName : 'Student',
          points: (existingS?.points ?? 0) + pts,
          wins: (existingS?.wins ?? 0) + (r.position == '1st' ? 1 : 0),
          className: r.className,
        );

        for (final clubId in r.clubIds) {
          final key = clubId.toString();
          final existingG = groupTotals[key];
          groupTotals[key] = LeaderboardEntry(
            id: clubId,
            name: existingG?.name ?? 'Club',
            points: (existingG?.points ?? 0) + pts,
            wins: (existingG?.wins ?? 0) + (r.position == '1st' ? 1 : 0),
          );
        }
      }

      for (final r in c.results) {
        if (r.position == '1st' || r.position == '2nd' || r.position == '3rd') {
          recent.add(
            RecentWin(
              event: c.name,
              date: c.date,
              position: r.position,
              student: r.studentName.isNotEmpty ? r.studentName : 'Student',
              className: r.className,
              compType: c.compType.value,
            ),
          );
        }
      }
    }

    int cmp(LeaderboardEntry a, LeaderboardEntry b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0 ? byPoints : b.wins.compareTo(a.wins);
    }

    recent.sort((a, b) => (DateTime.tryParse(b.date) ?? DateTime(0)).compareTo(DateTime.tryParse(a.date) ?? DateTime(0)));

    return InspireHubAggregates(
      events: events,
      eventCount: events.length,
      participantCount: events.fold(0, (s, c) => s + c.results.length),
      reviewCount: events.fold(0, (s, c) => s + c.results.where((r) => r.aiResponse.isNotEmpty).length),
      houses: housePoints.values.toList()..sort(cmp),
      students: studentTotals.values.toList()..sort(cmp),
      groups: groupTotals.values.toList()..sort(cmp),
      recent: recent.take(8).toList(),
      monthly: monthly,
    );
  }
}

/// Normalises a free-text title to "Title Case", preserving all-caps
/// acronyms and lower-casing small words mid-title — mirrors web's
/// `titleCase()`.
String titleCaseInspireHub(String s) {
  if (s.trim().isEmpty) return s;
  const small = {
    'a', 'an', 'and', 'as', 'at', 'but', 'by', 'for', 'in', 'of', 'on', 'or', 'the', 'to', 'vs', 'via',
  };
  final words = s.trim().split(RegExp(r'\s+'));
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (RegExp(r'^[A-Z]{2,}$').hasMatch(w)) {
      out.add(w);
    } else if (i > 0 && small.contains(w.toLowerCase())) {
      out.add(w.toLowerCase());
    } else {
      out.add(w[0].toUpperCase() + w.substring(1).toLowerCase());
    }
  }
  return out.join(' ');
}
