/// Shared dropdown option lists for the School Info screen's identity/address
/// fields — a straight port of frontend/lib/school-choices.ts, kept in sync
/// by hand for the same reason the web copy is hand-kept: the canonical
/// source (backend/apps/super_admin/views.py::SchoolFormChoicesView) is
/// super-admin-gated and this data barely changes.
library;

class IndianStateOption {
  final String code;
  final String name;

  const IndianStateOption({required this.code, required this.name});
}

const List<String> mediumOfInstructionOptions = [
  'English',
  'English & Hindi',
  'English & Telugu',
  'Telugu',
  'Hindi',
  'Urdu',
  'Kannada',
  'Tamil',
  'Marathi',
];

class BoardOption {
  final String value;
  final String label;

  const BoardOption({required this.value, required this.label});
}

const List<BoardOption> boardOptions = [
  BoardOption(value: 'CBSE', label: 'CBSE'),
  BoardOption(value: 'ICSE', label: 'ICSE'),
  BoardOption(value: 'SSC_TG', label: 'SSC TG'),
  BoardOption(value: 'SSC_AP', label: 'SSC AP'),
  BoardOption(value: 'OTHER', label: 'Other'),
];

final List<IndianStateOption> indianStateOptions = List.unmodifiable(
  [
    const IndianStateOption(code: '35', name: 'Andaman and Nicobar Islands'),
    const IndianStateOption(code: '37', name: 'Andhra Pradesh'),
    const IndianStateOption(code: '12', name: 'Arunachal Pradesh'),
    const IndianStateOption(code: '18', name: 'Assam'),
    const IndianStateOption(code: '10', name: 'Bihar'),
    const IndianStateOption(code: '04', name: 'Chandigarh'),
    const IndianStateOption(code: '22', name: 'Chhattisgarh'),
    const IndianStateOption(code: '26', name: 'Dadra and Nagar Haveli and Daman and Diu'),
    const IndianStateOption(code: '07', name: 'Delhi'),
    const IndianStateOption(code: '30', name: 'Goa'),
    const IndianStateOption(code: '24', name: 'Gujarat'),
    const IndianStateOption(code: '06', name: 'Haryana'),
    const IndianStateOption(code: '02', name: 'Himachal Pradesh'),
    const IndianStateOption(code: '01', name: 'Jammu and Kashmir'),
    const IndianStateOption(code: '20', name: 'Jharkhand'),
    const IndianStateOption(code: '29', name: 'Karnataka'),
    const IndianStateOption(code: '32', name: 'Kerala'),
    const IndianStateOption(code: '38', name: 'Ladakh'),
    const IndianStateOption(code: '31', name: 'Lakshadweep'),
    const IndianStateOption(code: '23', name: 'Madhya Pradesh'),
    const IndianStateOption(code: '27', name: 'Maharashtra'),
    const IndianStateOption(code: '14', name: 'Manipur'),
    const IndianStateOption(code: '17', name: 'Meghalaya'),
    const IndianStateOption(code: '15', name: 'Mizoram'),
    const IndianStateOption(code: '13', name: 'Nagaland'),
    const IndianStateOption(code: '21', name: 'Odisha'),
    const IndianStateOption(code: '34', name: 'Puducherry'),
    const IndianStateOption(code: '03', name: 'Punjab'),
    const IndianStateOption(code: '08', name: 'Rajasthan'),
    const IndianStateOption(code: '11', name: 'Sikkim'),
    const IndianStateOption(code: '33', name: 'Tamil Nadu'),
    const IndianStateOption(code: '36', name: 'Telangana'),
    const IndianStateOption(code: '16', name: 'Tripura'),
    const IndianStateOption(code: '09', name: 'Uttar Pradesh'),
    const IndianStateOption(code: '05', name: 'Uttarakhand'),
    const IndianStateOption(code: '19', name: 'West Bengal'),
  ]..sort((a, b) => a.name.compareTo(b.name)),
);

const List<String> regionOptions = ['north', 'south', 'east', 'west', 'northeast'];

// Maps each Indian state/UT code to one of regionOptions. There's no
// "central" bucket in this app's Region field, so Madhya Pradesh/
// Chhattisgarh are folded into their nearest neighbours (west/east) rather
// than left unmapped.
const Map<String, String> stateCodeToRegion = {
  '01': 'north', '02': 'north', '03': 'north', '04': 'north', '06': 'north',
  '07': 'north', '08': 'north', '09': 'north', '05': 'north', '38': 'north',
  '37': 'south', '36': 'south', '29': 'south', '32': 'south', '33': 'south',
  '34': 'south', '35': 'south', '31': 'south',
  '10': 'east', '20': 'east', '21': 'east', '19': 'east', '22': 'east',
  '24': 'west', '27': 'west', '30': 'west', '26': 'west', '23': 'west',
  '12': 'northeast', '18': 'northeast', '14': 'northeast', '17': 'northeast',
  '15': 'northeast', '13': 'northeast', '16': 'northeast', '11': 'northeast',
};

// Nominatim reverse-geocode returns full state names (with occasional
// variants); match them against indianStateOptions to recover the code the
// State dropdown uses.
const Map<String, String> _stateNameAliases = {
  'nct of delhi': 'Delhi',
  'national capital territory of delhi': 'Delhi',
  'orissa': 'Odisha',
  'pondicherry': 'Puducherry',
  'uttaranchal': 'Uttarakhand',
};

String? matchStateNameToCode(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final trimmed = name.trim();
  final normalized = _stateNameAliases[trimmed.toLowerCase()] ?? trimmed;
  for (final state in indianStateOptions) {
    if (state.name.toLowerCase() == normalized.toLowerCase()) return state.code;
  }
  return null;
}

/// Display label for a State field value (an Indian state/UT code) — used by
/// both the Review step and the map's reverse-geocode diff panel.
String stateLabel(String? code) {
  if (code == null || code.isEmpty) return '—';
  for (final state in indianStateOptions) {
    if (state.code == code) return state.name;
  }
  return '—';
}

/// Display label for a Region field value ("north" -> "North").
String regionLabel(String? region) {
  if (region == null || region.isEmpty) return '—';
  return region[0].toUpperCase() + region.substring(1);
}
