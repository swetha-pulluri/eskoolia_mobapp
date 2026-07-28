import 'package:flutter/material.dart';

/// One navigable page — mirrors frontend lib/routes.ts's `FLAT_INDEX` entry
/// shape (`{modId, label, path, icon, bg, ic}`), restricted to pages that
/// actually have a registered Flutter route (lib/config/router/app_router.dart)
/// — web's FLAT_INDEX also includes modules with no Flutter screen built yet
/// (Examination, Reports, HR, Library, Transport, etc.), which are
/// deliberately omitted here since navigating to them would 404.
class FlatIndexEntry {
  final String modId;
  final String label;
  final String path;
  final IconData icon;
  final Color bg;
  final Color ic;

  const FlatIndexEntry({
    required this.modId,
    required this.label,
    required this.path,
    required this.icon,
    required this.bg,
    required this.ic,
  });
}
