import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/school_header_store.dart';
import '../../domain/models/school_header_settings.dart';
import '../providers/student_providers.dart';
import '../utils/enrollment_pdf.dart';
import '../widgets/verification_form_ai_panel.dart';
import '../widgets/verification_form_document.dart';
import '../widgets/verification_form_settings_panel.dart';

enum _SignedUploadStatus { idle, uploading, done, error }

const Set<String> _kMinimalSections = {'govt', 'documents', 'medical', 'pwd', 'marks'};

/// The "Student Verification Form" full-screen document view — mirrors
/// `ConsentForm.tsx` exactly: a toolbar (Close / AI Assist / Header / Print /
/// Save PDF), a collapsible AI Layout Assistant panel, a collapsible Header
/// Settings panel, and the printable document itself. Opened from the Enroll
/// page's hero "PDF" button and footer "Print / PDF" button — see
/// `StudentEnrollPage._previewEnrollmentPdf`.
///
/// Mobile adaptation (disclosed): the frontend renders this as a fixed
/// full-screen overlay (`position: fixed; inset: 0`) with its own internal
/// scroll; here it is a pushed full-screen route — the same "takes over the
/// whole viewport, dismiss returns to the form" behavior, using Flutter's
/// own navigation stack instead of a manually-managed overlay. The toolbar
/// is pinned (not scrolled away) for reachability on a phone, whereas the
/// frontend's toolbar scrolls with the rest of the modal — a minimal,
/// disclosed touch-target adaptation, not a redesign.
class StudentVerificationFormPage extends ConsumerStatefulWidget {
  final EnrollmentPdfData data;

  const StudentVerificationFormPage({super.key, required this.data});

  @override
  ConsumerState<StudentVerificationFormPage> createState() => _StudentVerificationFormPageState();
}

class _StudentVerificationFormPageState extends ConsumerState<StudentVerificationFormPage> {
  final _headerStore = SchoolHeaderStore();
  late SchoolHeaderSettings _header;
  bool _showAi = false;
  bool _showSettings = false;
  Color _accentColor = const Color(0xFF6C3CE1);
  final Set<String> _hiddenSections = {};
  bool _generating = false;

  // "Upload signed copy" — mirrors ConsentForm.tsx's uploadStatus/
  // uploadedFileUrl/uploadedFileName/uploadError state exactly.
  _SignedUploadStatus _signedUploadStatus = _SignedUploadStatus.idle;
  String? _signedUploadedFileUrl;
  String? _signedUploadedFileName;
  String? _signedUploadError;

  @override
  void initState() {
    super.initState();
    _header = _headerStore.load();
  }

  String get _studentFullName => [widget.data.firstName, widget.data.middleName, widget.data.lastName].where((s) => s.trim().isNotEmpty).join(' ');

  void _toggleAi() => setState(() {
        _showAi = !_showAi;
        _showSettings = false;
      });

  void _toggleSettings() => setState(() {
        _showSettings = !_showSettings;
        _showAi = false;
      });

  void _applyPreset(String preset) => setState(() {
        _hiddenSections
          ..clear()
          ..addAll(preset == 'minimal' ? _kMinimalSections : const <String>{});
      });

  Future<void> _generatePdf() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      await printVerificationForm(
        data: widget.data,
        header: _header,
        accentColor: _accentColor,
        hiddenSections: _hiddenSections,
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Mirrors `handleSignedFormUpload()` exactly: gated on the student
  /// already having a real backend id, uploads via the same
  /// `document_type: 'consent_form'` endpoint the frontend uses.
  Future<void> _pickAndUploadSignedForm() async {
    final studentId = widget.data.studentId;
    if (studentId == null) {
      setState(() => _signedUploadError = 'Student must be saved before uploading a signed form.');
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    setState(() {
      _signedUploadStatus = _SignedUploadStatus.uploading;
      _signedUploadError = null;
    });
    try {
      final url = await ref.read(studentRepositoryProvider).uploadStudentDocument(
            studentId: studentId,
            documentType: 'consent_form',
            bytes: Uint8List.fromList(file.bytes!),
            filename: file.name,
          );
      if (!mounted) return;
      setState(() {
        _signedUploadedFileUrl = url;
        _signedUploadedFileName = file.name;
        _signedUploadStatus = _SignedUploadStatus.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _signedUploadStatus = _SignedUploadStatus.error;
        _signedUploadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _hasWarningTip => _header.logoBase64.isEmpty ||
      _header.schoolName == const SchoolHeaderSettings().schoolName ||
      widget.data.firstName.trim().isEmpty ||
      widget.data.admissionNo.trim().isEmpty ||
      widget.data.guardians.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showAi)
                            VerificationFormAiPanel(
                              data: widget.data,
                              header: _header,
                              accentColor: _accentColor,
                              onAccentColorChanged: (c) => setState(() => _accentColor = c),
                              hiddenSections: _hiddenSections,
                              onToggleSection: (id) => setState(() {
                                if (_hiddenSections.contains(id)) {
                                  _hiddenSections.remove(id);
                                } else {
                                  _hiddenSections.add(id);
                                }
                              }),
                              onShowAll: () => setState(_hiddenSections.clear),
                              onHideAll: () => setState(() {
                                _hiddenSections
                                  ..clear()
                                  ..addAll(kVerificationSections.map((s) => s.$1));
                              }),
                              onApplyPreset: _applyPreset,
                              onOpenHeaderSettings: () => setState(() {
                                _showAi = false;
                                _showSettings = true;
                              }),
                            ),
                          if (_showSettings)
                            VerificationFormSettingsPanel(
                              initial: _header,
                              studentFullName: _studentFullName,
                              onCancel: () => setState(() => _showSettings = false),
                              onSave: (settings) async {
                                await _headerStore.save(settings);
                                if (!mounted) return;
                                setState(() {
                                  _header = settings;
                                  _showSettings = false;
                                });
                              },
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                StudentVerificationDocument(
                                  data: widget.data,
                                  header: _header,
                                  accentColor: _accentColor,
                                  hiddenSections: _hiddenSections,
                                ),
                                _buildUploadSignedBar(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB)), backgroundColor: const Color(0xFFFAFAFA)),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Close'),
          ),
          const Text('Student Verification Form', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _AiAssistButton(active: _showAi, showDot: _hasWarningTip, onTap: _toggleAi),
              OutlinedButton.icon(
                onPressed: _toggleSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _showSettings ? const Color(0xFF6C3CE1) : const Color(0xFF374151),
                  side: BorderSide(color: _showSettings ? const Color(0xFFC4B5FD) : const Color(0xFFE5E7EB)),
                  backgroundColor: _showSettings ? const Color(0xFFF5F3FF) : const Color(0xFFFAFAFA),
                ),
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Header'),
              ),
              OutlinedButton.icon(
                onPressed: _generating ? null : _generatePdf,
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB)), backgroundColor: const Color(0xFFFAFAFA)),
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('Print'),
              ),
              ElevatedButton.icon(
                onPressed: _generating ? null : _generatePdf,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C3CE1), foregroundColor: Colors.white),
                icon: _generating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_outlined, size: 16),
                label: const Text('Save PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mirrors `.cf-upload-signed-bar` (screen-only, matches `no-print`: this
  /// never appears in the generated PDF, same as the reference) — sits
  /// directly below the signature lines, after everything else in the
  /// printable document.
  Widget _buildUploadSignedBar() {
    return LayoutBuilder(builder: (context, constraints) {
      final icon = Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF7C3AED)),
      );
      final textBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Upload signed copy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4C1D95))),
          const SizedBox(height: 2),
          Text(
            _signedUploadStatus == _SignedUploadStatus.done
                ? '✓ Saved: ${_signedUploadedFileName ?? ""}'
                : 'Print this form → get it signed → upload the scanned PDF or photo here to save it permanently.',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D28D9), height: 1.4),
          ),
        ],
      );
      // Row, not a bare Wrap: the left block must fill remaining space
      // (mirrors `.cf-upload-signed-left { flex:1 }`), which needs an
      // `Expanded`/`Flexible` context — a `LayoutBuilder`-driven stack is
      // the safe way to give it that AND still fall back to a vertical
      // layout on a narrow phone (mirrors `.cf-upload-signed-bar`'s own
      // `flex-wrap: wrap` exactly, without the "Row overflow" failure mode
      // a bare `Row` with fixed trailing content would have).
      final left = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [icon, const SizedBox(width: 12), Flexible(child: textBlock)],
      );
      final right = _buildUploadSignedActions();
      final stacked = constraints.maxWidth < 480;
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 24, 0, 8),
        child: CustomPaint(
          foregroundPainter: const _DashedBorderPainter(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFAF5FF), Color(0xFFF5F3FF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: stacked
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 12), right])
                : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: left), const SizedBox(width: 14), right]),
          ),
        ),
      );
    });
  }

  /// Mirrors `.cf-upload-signed-right`'s three states exactly: idle (Upload
  /// signed form button), uploading (spinner), done (View saved + Replace).
  Widget _buildUploadSignedActions() {
    if (_signedUploadStatus == _SignedUploadStatus.uploading) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))),
          SizedBox(width: 7),
          Text('Uploading…', style: TextStyle(fontSize: 13, color: Color(0xFF7C3AED), fontWeight: FontWeight.w500)),
        ],
      );
    }
    if (_signedUploadStatus == _SignedUploadStatus.done) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_signedUploadedFileUrl != null && _signedUploadedFileUrl!.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(_signedUploadedFileUrl!), mode: LaunchMode.externalApplication),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF065F46),
                backgroundColor: const Color(0xFFECFDF5),
                side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 14),
              label: const Text('View saved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _signedUploadStatus = _SignedUploadStatus.idle;
                _signedUploadedFileUrl = null;
                _signedUploadedFileName = null;
              });
              _pickAndUploadSignedForm();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Replace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: _pickAndUploadSignedForm,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF7C3AED),
            side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          ),
          icon: const Icon(Icons.upload_outlined, size: 14),
          label: const Text('Upload signed form', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        if (_signedUploadError != null) ...[
          const SizedBox(height: 6),
          Text('⚠ $_signedUploadError', style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
        ],
      ],
    );
  }
}

class _AiAssistButton extends StatelessWidget {
  final bool active;
  final bool showDot;
  final VoidCallback onTap;
  const _AiAssistButton({required this.active, required this.showDot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: active ? 0.45 : 0.3), blurRadius: active ? 12 : 8, offset: const Offset(0, 3))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                SizedBox(width: 6),
                Text('AI Assist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
            if (showDot)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rect border — mirrors `.cf-upload-signed-bar`'s
/// `border: 1.5px dashed #c4b5fd` exactly (Flutter has no built-in dashed
/// `BoxBorder`, so this small painter is the direct equivalent rather than
/// a plain solid border standing in for it).
class _DashedBorderPainter extends CustomPainter {
  static const _color = Color(0xFFC4B5FD);
  static const _radius = 12.0;
  static const _strokeWidth = 1.5;
  static const _dashWidth = 5.0;
  static const _dashGap = 4.0;

  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_strokeWidth / 2, _strokeWidth / 2, size.width - _strokeWidth, size.height - _strokeWidth),
      Radius.circular(_radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
