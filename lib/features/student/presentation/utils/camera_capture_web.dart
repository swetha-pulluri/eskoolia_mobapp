// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Web: mirrors `StudentAddPanel.tsx`'s in-page camera modal exactly —
/// `getUserMedia` + a live `<video>` preview + Capture/Retake/Use photo/
/// Cancel — since a browser has no native camera app to hand off to the
/// way a phone OS does.
Future<Uint8List?> captureStudentPhotoViaCamera(BuildContext context) {
  return showDialog<Uint8List?>(
    context: context,
    barrierColor: const Color(0xB80F172A),
    builder: (context) => const _CameraCaptureDialog(),
  );
}

class _CameraCaptureDialog extends StatefulWidget {
  const _CameraCaptureDialog();

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  final String _viewType = 'camera-video-view-${DateTime.now().microsecondsSinceEpoch}';
  html.MediaStream? _stream;
  html.VideoElement? _video;
  Uint8List? _capturedBytes;
  String? _error;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  void _stopCamera() {
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;
    if (_video != null) _video!.srcObject = null;
  }

  Future<void> _startCamera() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      setState(() => _error = 'Camera access is not supported on this device.');
      return;
    }
    // Mirrors StudentAddPanel.tsx's own fallback chain exactly: prefer the
    // rear/environment camera at a reasonable resolution, then the front
    // camera, then whatever camera is available at all.
    final constraintsList = [
      {
        'video': {'facingMode': {'ideal': 'environment'}, 'width': {'ideal': 1280}, 'height': {'ideal': 960}},
        'audio': false,
      },
      {
        'video': {'facingMode': 'user', 'width': {'ideal': 1280}, 'height': {'ideal': 960}},
        'audio': false,
      },
      {'video': true, 'audio': false},
    ];

    html.MediaStream? stream;
    Object? lastError;
    for (final constraints in constraintsList) {
      try {
        stream = await mediaDevices.getUserMedia(constraints);
        break;
      } catch (e) {
        lastError = e;
      }
    }

    if (!mounted) {
      stream?.getTracks().forEach((track) => track.stop());
      return;
    }
    if (stream == null) {
      setState(() => _error = _describeCameraError(lastError));
      return;
    }

    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..srcObject = stream;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => video);

    _stream = stream;
    _video = video;
    try {
      await video.play();
    } catch (_) {
      // Some browsers need metadata before playback can start.
    }
    if (!mounted) {
      _stopCamera();
      return;
    }
    setState(() => _ready = true);
  }

  String _describeCameraError(Object? error) {
    if (error is html.DomException && error.name == 'NotAllowedError') {
      return 'Camera permission was blocked. Allow camera access in the browser and try again.';
    }
    return 'Unable to access camera.';
  }

  Future<void> _capture() async {
    final video = _video;
    if (video == null || video.videoWidth == 0 || video.videoHeight == 0) {
      setState(() => _error = 'Camera is not ready yet.');
      return;
    }
    setState(() => _busy = true);
    try {
      final canvas = html.CanvasElement(width: video.videoWidth, height: video.videoHeight);
      final ctx = canvas.context2D;
      ctx.drawImage(video, 0, 0);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);
      final marker = dataUrl.indexOf(',');
      if (marker == -1) throw Exception('Unable to capture photo.');
      setState(() {
        _capturedBytes = base64Decode(dataUrl.substring(marker + 1));
        _error = null;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to capture photo.';
        _busy = false;
      });
    }
  }

  void _retake() {
    setState(() {
      _capturedBytes = null;
      _error = null;
    });
  }

  void _usePhoto() {
    final bytes = _capturedBytes;
    _stopCamera();
    Navigator.of(context).pop(bytes);
  }

  void _cancel() {
    _stopCamera();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: const Color(0x470F172A), blurRadius: 50, offset: const Offset(0, 18))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Take photo', style: TextStyle(fontSize: 18, color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Use your camera to capture the student photo.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _cancel,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(8)),
                        child: const Text('✕', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                color: const Color(0xFF0F172A),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFFECACA))),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          color: const Color(0xFF020617),
                          child: _capturedBytes != null
                              ? Image.memory(_capturedBytes!, fit: BoxFit.contain)
                              : _ready
                                  ? HtmlElementView(viewType: _viewType)
                                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  // Mirrors `.btn-upload-file` (outlined, neutral) vs
                  // `.btn-take-photo` (plain underlined brand-colour text
                  // link, not a filled button) exactly.
                  children: _capturedBytes != null
                      ? [
                          _outlinedButton('Retake', _busy ? null : _retake),
                          const SizedBox(width: 10),
                          _linkButton('Use photo', _busy ? null : _usePhoto),
                        ]
                      : [
                          _outlinedButton('Cancel', _cancel),
                          const SizedBox(width: 10),
                          _linkButton('Capture', (_busy || !_ready) ? null : _capture),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlinedButton(String label, VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
      ),
      child: Text(label),
    );
  }

  Widget _linkButton(String label, VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C3CE1), padding: EdgeInsets.zero),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, decoration: TextDecoration.underline)),
    );
  }
}
