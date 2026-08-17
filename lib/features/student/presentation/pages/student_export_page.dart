import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../fees/presentation/utils/pdf_unicode_theme.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../../domain/repositories/student_repository.dart';
import '../providers/student_providers.dart';

/// "Student Export" — the Reports sub-nav's 14th, real (non-"Coming Soon")
/// item on web (`routes.ts`'s Reports `sub` array, last entry: `{ label:
/// 'Student Export', path: '/students/export' }`), rendered by
/// `StudentExportPanel.tsx`. That panel does NOT call the backend's
/// dedicated `GET /api/v1/students/students/export-xlsx/` action (confirmed
/// unused, dead code on web) — instead it fetches the plain student list
/// (`/api/v1/students/students/`, filterable by class/section/status) and
/// builds the CSV/PDF client-side. Ported the same way here, reusing the
/// Student feature's existing `fetchClasses`/`fetchStudentsFiltered` (no new
/// backend calls needed) rather than the unused xlsx endpoint, so this
/// matches what web actually does, not what it merely could do.
enum _ExportColumn { sl, admissionNo, rollNo, name, classSection, gender, dateOfBirth, status }

class _ColumnDef {
  final _ExportColumn key;
  final String label;
  final bool defaultChecked;
  const _ColumnDef(this.key, this.label, this.defaultChecked);
}

/// Mirrors `COLUMN_DEFINITIONS` exactly (key/label/defaultChecked order).
const _kColumns = [
  _ColumnDef(_ExportColumn.sl, 'SL', true),
  _ColumnDef(_ExportColumn.admissionNo, 'ID', true),
  _ColumnDef(_ExportColumn.rollNo, 'Roll No', true),
  _ColumnDef(_ExportColumn.name, 'Name', true),
  _ColumnDef(_ExportColumn.classSection, 'Class (Section)', true),
  _ColumnDef(_ExportColumn.gender, 'Gender', true),
  _ColumnDef(_ExportColumn.dateOfBirth, 'Date Of Birth', false),
  _ColumnDef(_ExportColumn.status, 'Status', true),
];

class StudentExportPage extends ConsumerStatefulWidget {
  const StudentExportPage({super.key});

  @override
  ConsumerState<StudentExportPage> createState() => _StudentExportPageState();
}

class _StudentExportPageState extends ConsumerState<StudentExportPage> {
  List<SchoolClass> _classes = [];

  /// The server-reported total matching the current filters — shown in the
  /// "N Students Ready" badge and refreshed cheaply (`page_size=1`, reading
  /// just `.count`). The full row-by-row data (needed only to actually
  /// build a CSV/PDF) is fetched fresh, once, at export time instead — see
  /// `_exportCsv`/`_exportPdf`. Eagerly paginating through every matching
  /// student on every page load/filter change/Refresh tap (the previous
  /// approach) made the whole panel sit disabled for as long as that full
  /// fetch took, which for a school with more than a page or two of
  /// students was a long, indefinite-feeling wait for no benefit before the
  /// user had even chosen to export anything.
  int _studentCount = 0;

  int? _classId;
  int? _sectionId;
  String _statusFilter = 'all'; // all | active | inactive

  bool _loading = true;
  bool _refreshing = false;
  bool _exportingCsv = false;
  bool _exportingPdf = false;
  bool _filtersOpen = true;
  String? _error;
  String? _success;

  final Set<_ExportColumn> _selectedColumns = _kColumns.where((c) => c.defaultChecked).map((c) => c.key).toSet();

  List<SectionData> get _sectionsForSelectedClass {
    final classId = _classId;
    if (classId == null) return const [];
    for (final c in _classes) {
      if (c.id == classId) return c.sections;
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<List<StudentData>> _fetchAllStudents(StudentRepository repo) async {
    final accumulated = <StudentData>[];
    var page = 1;
    const pageSize = 200;
    while (true) {
      final result = await repo.fetchStudentsFiltered(
        classId: _classId,
        sectionId: _sectionId,
        isActive: _statusFilter == 'active' ? true : (_statusFilter == 'inactive' ? false : null),
        page: page,
        pageSize: pageSize,
      );
      accumulated.addAll(result.results);
      if (result.results.isEmpty || accumulated.length >= result.count) break;
      page++;
    }
    return accumulated;
  }

  Future<void> _loadClasses() async {
    try {
      // Cached provider (`reportsExportClassesProvider`), not a direct
      // repository call — every mount of this page previously re-issued
      // `GET /api/v1/core/classes/` from scratch even within the same
      // session; the provider (not `.autoDispose`) resolves instantly from
      // cache on any visit after the first.
      final classes = await ref.read(reportsExportClassesProvider.future);
      if (mounted) setState(() => _classes = classes);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load classes.');
    }
  }

  Future<void> _loadCount() async {
    try {
      final result = await ref.read(studentRepositoryProvider).fetchStudentsFiltered(
            classId: _classId,
            sectionId: _sectionId,
            isActive: _statusFilter == 'active' ? true : (_statusFilter == 'inactive' ? false : null),
            page: 1,
            pageSize: 1,
          );
      if (mounted) setState(() => _studentCount = result.count);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load students for export.');
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    // Run independently — a class-load failure must not also blank out an
    // already-fetched count, and vice versa. Chaining these inside one
    // try/await previously meant a students-fetch failure silently dropped
    // the classes result too (its own `setState` never ran), which is what
    // was emptying the "All Classes" dropdown even when `/core/classes/`
    // itself succeeded.
    await Future.wait([_loadClasses(), _loadCount()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
      _success = null;
    });
    await _loadCount();
    if (mounted) {
      setState(() {
        _refreshing = false;
        if (_error == null) _success = 'Student count updated successfully.';
      });
    }
  }

  String _cell(_ExportColumn col, StudentData s, int index) {
    switch (col) {
      case _ExportColumn.sl:
        return '${index + 1}';
      case _ExportColumn.admissionNo:
        return s.admissionNo.isEmpty ? '-' : s.admissionNo;
      case _ExportColumn.rollNo:
        return (s.rollNo == null || s.rollNo!.isEmpty) ? '-' : s.rollNo!;
      case _ExportColumn.name:
        return s.fullName.isEmpty ? '-' : s.fullName;
      case _ExportColumn.classSection:
        final cls = s.className.isEmpty ? '-' : s.className;
        final sec = s.sectionName.isEmpty ? '-' : s.sectionName;
        return '$cls ($sec)';
      case _ExportColumn.gender:
        return s.gender?.label ?? '-';
      case _ExportColumn.dateOfBirth:
        final dob = s.dateOfBirth;
        return dob == null ? '-' : DateFormat('M/d/yyyy').format(dob);
      case _ExportColumn.status:
        return s.isActive ? (s.isDisabled ? 'Disabled' : 'Active') : 'Inactive';
    }
  }

  Future<bool> _confirmExport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Export'),
        content: Text('You are about to export $_studentCount student records. This may take a moment. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

  Future<void> _exportCsv() async {
    if (_studentCount == 0) {
      setState(() {
        _error = 'No student data available to export.';
        _success = null;
      });
      return;
    }
    if (!await _confirmExport()) return;
    setState(() {
      _exportingCsv = true;
      _error = null;
      _success = null;
    });
    try {
      final students = await _fetchAllStudents(ref.read(studentRepositoryProvider));
      final cols = _kColumns.where((c) => _selectedColumns.contains(c.key)).toList();
      final lines = <String>[
        cols.map((c) => _escapeCsv(c.label)).join(','),
        for (var i = 0; i < students.length; i++) cols.map((c) => _escapeCsv(_cell(c.key, students[i], i))).join(','),
      ];
      // Leading BOM matches web's `﻿` prefix exactly — keeps Excel from
      // mis-detecting the encoding of non-ASCII names.
      final csv = '﻿${lines.join('\n')}';
      await saveBytesForDownload(bytes: Uint8List.fromList(utf8.encode(csv)), filename: 'all-students-export.csv');
      if (mounted) setState(() => _success = 'CSV exported successfully.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_studentCount == 0) {
      setState(() {
        _error = 'No student data available to export.';
        _success = null;
      });
      return;
    }
    if (!await _confirmExport()) return;
    setState(() {
      _exportingPdf = true;
      _error = null;
      _success = null;
    });
    try {
      final students = await _fetchAllStudents(ref.read(studentRepositoryProvider));
      final cols = _kColumns.where((c) => _selectedColumns.contains(c.key)).toList();
      final doc = pw.Document(theme: await pdfUnicodeTheme());
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => context.pageNumber == 1
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('All Student Export', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Export contains sensitive student information.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 10),
                  ],
                )
              : pw.SizedBox(),
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6D28D9)),
                  children: [
                    for (final c in cols)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Text(c.label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                  ],
                ),
                for (var i = 0; i < students.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFF9FAFB)),
                    children: [
                      for (final c in cols)
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: pw.Text(_cell(c.key, students[i], i), style: const pw.TextStyle(fontSize: 8)),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'all-students-export.pdf');
      if (mounted) setState(() => _success = 'PDF exported successfully.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final generating = _exportingCsv || _exportingPdf;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matches `StudentExportPanel.tsx`'s `.student-page-header`
              // exactly: title stacked directly above the breadcrumb, both
              // left-aligned — unlike the Report Explorer's title-left/
              // breadcrumb-right row layout, this page's own web source
              // uses a plain stacked header instead.
              const Text('Student Export', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Dashboard/Student Information/Student Export', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        const Text('All Student Export', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), border: Border.all(color: const Color(0xFFBFDBFE)), borderRadius: BorderRadius.circular(999)),
                          child: Text('$_studentCount Students Ready', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter Before Export
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.bgSecondary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Filter Before Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              InkWell(
                                onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                                child: Text(_filtersOpen ? 'Collapse' : 'Expand', style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB))),
                              ),
                            ],
                          ),
                          if (_filtersOpen) ...[
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 700 ? 4 : (constraints.maxWidth >= 480 ? 2 : 1);
                                const spacing = 10.0;
                                final fieldWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(width: fieldWidth, child: _classField()),
                                    SizedBox(width: fieldWidth, child: _sectionField()),
                                    SizedBox(width: fieldWidth, child: _statusField()),
                                    SizedBox(
                                      width: fieldWidth,
                                      child: ElevatedButton(
                                        onPressed: _loading || _refreshing ? null : _refresh,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, 36),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text(_refreshing ? 'Refreshing…' : 'Refresh Count'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Select Export Columns
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Export Columns', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              for (final c in _kColumns)
                                InkWell(
                                  onTap: () => setState(() {
                                    if (_selectedColumns.contains(c.key)) {
                                      if (_selectedColumns.length > 1) _selectedColumns.remove(c.key);
                                    } else {
                                      _selectedColumns.add(c.key);
                                    }
                                  }),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _selectedColumns.contains(c.key),
                                        onChanged: (_) => setState(() {
                                          if (_selectedColumns.contains(c.key)) {
                                            if (_selectedColumns.length > 1) _selectedColumns.remove(c.key);
                                          } else {
                                            _selectedColumns.add(c.key);
                                          }
                                        }),
                                      ),
                                      Text(c.label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Export contains sensitive student information.', style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E))),
                    ),
                    const SizedBox(height: 6),
                    const Text('Large exports may take time. CSV is better for spreadsheet processing.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const SizedBox(height: 14),

                    Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: (_loading || generating) ? null : _exportCsv,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(_exportingCsv ? 'Generating…' : 'Export to CSV'),
                          ),
                          ElevatedButton(
                            onPressed: (_loading || generating) ? null : _exportPdf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(_exportingPdf ? 'Generating…' : 'Export to PDF'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loading ? 'Loading student data...' : 'Total students ready for export: $_studentCount',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 12.5))),
                    if (_success != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_success!, style: const TextStyle(color: AppColors.successGreen, fontSize: 12.5))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        input,
      ],
    );
  }

  Widget _classField() {
    return _labeled(
      'Class',
      AppDropdown<int?>(
        value: _classId,
        hint: const Text('All Classes', style: TextStyle(fontSize: 12)),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Classes')),
          for (final c in _classes) DropdownMenuItem(value: c.id, child: Text(c.displayLabel, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: _loading
            ? null
            : (v) => setState(() {
                  _classId = v;
                  _sectionId = null;
                }),
      ),
    );
  }

  Widget _sectionField() {
    final sections = _sectionsForSelectedClass;
    return _labeled(
      'Section',
      AppDropdown<int?>(
        value: _sectionId,
        hint: Text(_classId == null ? 'Select Class First' : 'All Sections', style: const TextStyle(fontSize: 12)),
        items: [
          DropdownMenuItem(value: null, child: Text(_classId == null ? 'Select Class First' : 'All Sections')),
          for (final s in sections) DropdownMenuItem(value: s.id, child: Text(s.displayLabel, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (_loading || _classId == null) ? null : (v) => setState(() => _sectionId = v),
      ),
    );
  }

  Widget _statusField() {
    return _labeled(
      'Status',
      AppDropdown<String>(
        value: _statusFilter,
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All')),
          DropdownMenuItem(value: 'active', child: Text('Active')),
          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
        ],
        onChanged: _loading ? null : (v) => setState(() => _statusFilter = v ?? 'all'),
      ),
    );
  }
}
