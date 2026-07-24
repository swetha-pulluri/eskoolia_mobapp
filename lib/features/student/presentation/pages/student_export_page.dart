import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/models/school_class.dart';
import '../providers/student_providers.dart';
import '../widgets/student_subpage_header.dart';

/// Student Export — mirrors frontend components/students/
/// StudentExportPanel.tsx's filter UI (Class/Section/Status), but wired to
/// the ONE real backend export endpoint instead of the reference
/// frontend's own client-side CSV Blob-download / browser-print-to-PDF
/// trick (which makes zero backend calls at all).
///
/// Disclosed deviation from "identical to frontend": the reference screen
/// offers CSV + PDF formats and an 8-checkbox column picker, none of which
/// any backend endpoint supports — only `GET .../students/export-xlsx/`
/// exists, producing a fixed 8-column .xlsx (Admission No, Student, Class,
/// Section, Guardian, Phone, DOB, Status). Rather than fake CSV/PDF output
/// or a column picker that does nothing, this screen offers exactly the
/// one export the backend can actually perform.
class StudentExportPage extends ConsumerStatefulWidget {
  const StudentExportPage({super.key});

  @override
  ConsumerState<StudentExportPage> createState() => _StudentExportPageState();
}

class _StudentExportPageState extends ConsumerState<StudentExportPage> {
  List<SchoolClass> _classes = [];
  int? _classId;
  int? _sectionId;
  bool? _isActive; // null = all
  bool _loadingClasses = true;
  bool _exporting = false;
  String? _lastSavedPath;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await ref.read(studentRepositoryProvider).fetchClasses();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _loadingClasses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingClasses = false);
    }
  }

  List<SectionData> get _sectionsForClass =>
      _classes.where((c) => c.id == _classId).firstOrNull?.sections ?? const [];

  Future<void> _export() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Export'),
        content: const Text('You are about to export student records to an Excel (.xlsx) file. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Proceed')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(studentRepositoryProvider).exportStudentsXlsx(
            classId: _classId,
            sectionId: _sectionId,
            isActive: _isActive,
          );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${Directory.systemTemp.path}/students-export-$timestamp.xlsx');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _lastSavedPath = file.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${(bytes.length / 1024).toStringAsFixed(1)} KB to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            StudentSubpageHeader(
              titlePlain: 'Student ',
              titleAccent: 'Export',
              accentColor: const Color(0xFF1D4ED8),
              subtitle: 'Export student records to an Excel spreadsheet.',
              actions: [
                OutlinedButton(onPressed: () => context.go('/students'), child: const Text('Student List')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppDropdown<int>(
                          value: _classId,
                          hint: const Text('All classes', style: TextStyle(fontSize: 12)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All classes')),
                            ..._classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: _loadingClasses
                              ? null
                              : (v) => setState(() {
                                    _classId = v;
                                    _sectionId = null;
                                  }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppDropdown<int>(
                          value: _sectionId,
                          hint: const Text('All sections', style: TextStyle(fontSize: 12)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All sections')),
                            ..._sectionsForClass.map((s) => DropdownMenuItem(value: s.id, child: Text('Section ${s.name}'))),
                          ],
                          onChanged: _classId == null ? null : (v) => setState(() => _sectionId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppDropdown<bool>(
                    value: _isActive,
                    hint: const Text('All statuses', style: TextStyle(fontSize: 12)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All statuses')),
                      DropdownMenuItem(value: true, child: Text('Active')),
                      DropdownMenuItem(value: false, child: Text('Inactive')),
                    ],
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(8)),
                    child: const Text(
                      'Export contains sensitive student information. Handle the downloaded file carefully.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _export,
                      icon: _exporting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.file_download_outlined, size: 16),
                      label: Text(_exporting ? 'Generating…' : 'Export to Excel (.xlsx)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  if (_lastSavedPath != null) ...[
                    const SizedBox(height: 10),
                    Text('Last export saved to: $_lastSavedPath', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
