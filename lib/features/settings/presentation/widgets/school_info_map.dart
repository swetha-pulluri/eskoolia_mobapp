import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

const LatLng _defaultCenter = LatLng(20.5937, 78.9629); // India
const Color _geofenceFill = Color(0x1F6D4AFF); // purpleAccent @ ~12% alpha

/// Campus location map — mirrors `SchoolLocationMap.tsx` (Leaflet + OSM
/// tiles): tap to drop a pin, drag the pin to adjust, an optional geofence
/// radius circle. flutter_map has no built-in draggable marker, so dragging
/// is implemented by hand via [MapCamera.latLngToScreenPoint] /
/// [MapCamera.pointToLatLng] — both explicitly documented for converting
/// between a [LatLng] and "a position usable with a widget outside of
/// FlutterMap layer space", which is exactly this marker's [GestureDetector].
class SchoolInfoMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final int? radiusMeters;
  final void Function(double lat, double lng) onChanged;

  const SchoolInfoMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.onChanged,
  });

  @override
  State<SchoolInfoMap> createState() => _SchoolInfoMapState();
}

class _SchoolInfoMapState extends State<SchoolInfoMap> {
  final MapController _mapController = MapController();
  LatLng? _dragPreview;

  LatLng? get _point {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  void didUpdateWidget(covariant SchoolInfoMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude || widget.longitude != oldWidget.longitude) {
      _dragPreview = null;
      final point = _point;
      if (point != null) {
        final zoom = _mapController.camera.zoom;
        _mapController.move(point, zoom < 15 ? 15.0 : zoom);
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final camera = _mapController.camera;
    final current = _dragPreview ?? _point;
    if (current == null) return;
    final screenPoint = camera.latLngToScreenPoint(current);
    final moved = math.Point<double>(
      screenPoint.x + details.delta.dx,
      screenPoint.y + details.delta.dy,
    );
    setState(() => _dragPreview = camera.pointToLatLng(moved));
  }

  void _handlePanEnd() {
    final result = _dragPreview;
    if (result != null) {
      widget.onChanged(result.latitude, result.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = _dragPreview ?? _point;
    final hasPoint = point != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: point ?? _defaultCenter,
            initialZoom: hasPoint ? 16 : 5,
            onTap: (_, tapped) => widget.onChanged(tapped.latitude, tapped.longitude),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.eskoolia.mobapp',
            ),
            if (hasPoint && (widget.radiusMeters ?? 0) > 0)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: point,
                    radius: widget.radiusMeters!.toDouble(),
                    useRadiusInMeter: true,
                    color: _geofenceFill,
                    borderColor: AppColors.purpleAccent,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            if (hasPoint)
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 30,
                    height: 30,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: (_) => _handlePanEnd(),
                      child: const _MapPin(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A purple teardrop pin — mirrors `SchoolLocationMap.tsx`'s `L.divIcon`
/// (30x30 rotated square with three square corners and one round corner).
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -math.pi / 4,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.purpleAccent,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(13),
              topRight: Radius.circular(13),
              bottomRight: Radius.circular(13),
            ),
            boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 5, offset: Offset(0, 2))],
          ),
        ),
      ),
    );
  }
}
