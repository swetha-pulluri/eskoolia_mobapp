import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/logger.dart';
import '../../../../data/local/branding_cache_service.dart';
import '../../domain/entities/user_entity.dart';

/// Current school branding for this device — last known-good, cache-first.
/// [brandColor] feeds `AppTheme.lightTheme`; [logoFile] feeds the splash
/// screen. Both are `null` when no school has configured branding yet, in
/// which case callers fall back to the static eSkoolia defaults.
class BrandingState {
  final Color? brandColor;
  final File? logoFile;

  const BrandingState({this.brandColor, this.logoFile});

  BrandingState copyWith({Color? brandColor, bool clearBrandColor = false, File? logoFile, bool clearLogoFile = false}) {
    return BrandingState(
      brandColor: clearBrandColor ? null : (brandColor ?? this.brandColor),
      logoFile: clearLogoFile ? null : (logoFile ?? this.logoFile),
    );
  }
}

/// `#rrggbb` (the only format the backend ever sends — see
/// `SchoolTenant.brand_color` / `SchoolInfoPanel.tsx`'s `<input
/// type="color">`) → [Color]. Returns null for anything else (unset,
/// malformed) rather than guessing.
Color? parseBrandColorHex(String? hex) {
  if (hex == null) return null;
  final trimmed = hex.trim();
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(trimmed);
  if (match == null) return null;
  final value = int.parse(match.group(1)!, radix: 16);
  return Color(0xFF000000 | value);
}

class BrandingNotifier extends StateNotifier<BrandingState> {
  final BrandingCacheService _cache;

  BrandingNotifier(this._cache) : super(const BrandingState()) {
    final cached = _cache.read();
    final logoPath = cached.logoLocalPath;
    state = BrandingState(
      brandColor: parseBrandColorHex(cached.brandColorHex),
      logoFile: logoPath != null && File(logoPath).existsSync() ? File(logoPath) : null,
    );
  }

  /// Applies [branding] for the currently authenticated user. The color is
  /// resolved and applied immediately (no network needed — it's already in
  /// the `/auth/me/` payload), so a different school logging in on the same
  /// device gets its color right away. The logo is only re-downloaded when
  /// its URL (or the school itself) changed, and any failure here is logged
  /// and swallowed — branding sync must never affect auth state.
  Future<void> syncFromUser(SchoolBrandingEntity? branding, Dio dio, {int? schoolId}) async {
    final newColor = parseBrandColorHex(branding?.brandColorHex);
    state = state.copyWith(brandColor: newColor, clearBrandColor: newColor == null);
    await _cache.saveColor(schoolId: schoolId, brandColorHex: branding?.brandColorHex);

    final newLogoUrl = branding?.logoUrl;
    final cached = _cache.read();
    final schoolChanged = schoolId != null && cached.schoolId != null && cached.schoolId != schoolId;
    final urlUnchanged = !schoolChanged && cached.logoUrl == newLogoUrl;

    if (newLogoUrl == null || newLogoUrl.isEmpty) {
      if (cached.logoLocalPath != null) await _deleteLogoFile(cached.logoLocalPath);
      await _cache.saveLogo(logoUrl: null, logoLocalPath: null);
      state = state.copyWith(clearLogoFile: true);
      return;
    }

    if (urlUnchanged && state.logoFile != null && state.logoFile!.existsSync()) {
      return;
    }

    try {
      // Dio's configured `baseUrl` (`ApiConstants.baseUrl`) combines
      // automatically with a relative `/media/...` path; an already-
      // absolute `http(s)` URL is used as-is either way.
      final response = await dio.get<List<int>>(
        newLogoUrl,
        options: Options(responseType: ResponseType.bytes, extra: {'silent': true}),
      );
      final bytes = response.data;
      if (bytes == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final ext = _extensionOf(newLogoUrl);
      final file = File('${dir.path}/school_logo_${schoolId ?? 'current'}$ext');
      await file.writeAsBytes(bytes, flush: true);

      if (cached.logoLocalPath != null && cached.logoLocalPath != file.path) {
        await _deleteLogoFile(cached.logoLocalPath);
      }

      await _cache.saveLogo(logoUrl: newLogoUrl, logoLocalPath: file.path);
      state = state.copyWith(logoFile: file);
    } catch (e) {
      AppLogger.error('[BrandingNotifier] logo download failed, keeping cached branding', e);
    }
  }

  Future<void> _deleteLogoFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  String _extensionOf(String url) {
    final withoutQuery = url.split('?').first;
    final dot = withoutQuery.lastIndexOf('.');
    if (dot == -1 || dot == withoutQuery.length - 1) return '.png';
    final ext = withoutQuery.substring(dot).toLowerCase();
    return ext.length <= 5 ? ext : '.png';
  }
}
