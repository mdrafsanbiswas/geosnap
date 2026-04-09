import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/geo_point.dart';
import '../constants/attendance_ui_color.dart';
import '../constants/attendance_ui_text.dart';

class OfficeLocationCard extends StatefulWidget {
  const OfficeLocationCard({
    required this.officeLocation,
    required this.currentLocation,
    required this.isLoading,
    required this.currentLocationMarkerIcon,
    required this.officeLocationMarkerIcon,
    required this.onSetOfficeLocation,
    required this.onResetOfficeLocation,
    super.key,
  });

  final GeoPoint? officeLocation;
  final GeoPoint? currentLocation;
  final bool isLoading;
  final BitmapDescriptor? currentLocationMarkerIcon;
  final BitmapDescriptor? officeLocationMarkerIcon;
  final VoidCallback onSetOfficeLocation;
  final VoidCallback onResetOfficeLocation;

  @override
  State<OfficeLocationCard> createState() => _OfficeLocationCardState();
}

class _OfficeLocationCardState extends State<OfficeLocationCard> {
  bool _isMapReady = false;

  @override
  void didUpdateWidget(covariant OfficeLocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadPreview =
        oldWidget.officeLocation != null || oldWidget.currentLocation != null;
    final hasPreview =
        widget.officeLocation != null || widget.currentLocation != null;
    if (hadPreview != hasPreview && _isMapReady) {
      setState(() {
        _isMapReady = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewLocation = widget.officeLocation ?? widget.currentLocation;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mapHeight = (screenHeight * 0.28).clamp(170.0, 220.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AttendanceUiColor.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AttendanceUiText.officeTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AttendanceUiColor.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.officeLocation != null)
                  TextButton.icon(
                    onPressed: widget.isLoading
                        ? null
                        : widget.onResetOfficeLocation,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(AttendanceUiText.reset),
                    style: TextButton.styleFrom(
                      foregroundColor: AttendanceUiColor.brand,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.officeLocation == null
                  ? AttendanceUiText.officeHintSet
                  : AttendanceUiText.officeHintLocked,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AttendanceUiColor.body,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: mapHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (previewLocation == null)
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AttendanceUiColor.mapBgA,
                              AttendanceUiColor.mapBgB,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_searching,
                            size: 40,
                            color: AttendanceUiColor.mapIcon,
                          ),
                        ),
                      )
                    else
                      GoogleMap(
                        onMapCreated: (_) {
                          if (!_isMapReady && mounted) {
                            setState(() {
                              _isMapReady = true;
                            });
                          }
                        },
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        zoomGesturesEnabled: true,
                        // Keep the card preview anchored while allowing zoom in/out.
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            previewLocation.latitude,
                            previewLocation.longitude,
                          ),
                          zoom: 17,
                        ),
                        markers: {
                          if (widget.officeLocation != null)
                            Marker(
                              markerId: const MarkerId(
                                AttendanceUiText.officeMarkerId,
                              ),
                              position: LatLng(
                                widget.officeLocation!.latitude,
                                widget.officeLocation!.longitude,
                              ),
                              zIndexInt: 1,
                              icon:
                                  widget.officeLocationMarkerIcon ??
                                  BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                              anchor: const Offset(0.5, 1),
                              infoWindow: const InfoWindow(
                                title: AttendanceUiText.officeMarkerTitle,
                              ),
                            ),
                          if (widget.currentLocation != null)
                            Marker(
                              markerId: const MarkerId(
                                AttendanceUiText.currentMarkerId,
                              ),
                              position: LatLng(
                                widget.currentLocation!.latitude,
                                widget.currentLocation!.longitude,
                              ),
                              zIndexInt: 2,
                              icon:
                                  widget.currentLocationMarkerIcon ??
                                  BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueAzure,
                                  ),
                              anchor: const Offset(0.5, 0.5),
                              infoWindow: const InfoWindow(
                                title: AttendanceUiText.currentMarkerTitle,
                              ),
                            ),
                        },
                        circles: {
                          if (widget.officeLocation != null)
                            Circle(
                              circleId: const CircleId(
                                AttendanceUiText.officeRadiusId,
                              ),
                              center: LatLng(
                                widget.officeLocation!.latitude,
                                widget.officeLocation!.longitude,
                              ),
                              radius: AppConstants.attendanceRadiusInMeters,
                              strokeColor: AttendanceUiColor.danger,
                              fillColor: AttendanceUiColor.officeRadiusFill,
                              strokeWidth: 2,
                            ),
                          if (widget.currentLocation != null)
                            Circle(
                              circleId: const CircleId(
                                AttendanceUiText.currentAccuracyId,
                              ),
                              center: LatLng(
                                widget.currentLocation!.latitude,
                                widget.currentLocation!.longitude,
                              ),
                              radius: _currentLocationAccuracyRadius(
                                widget.currentLocation!.accuracyInMeters,
                              ),
                              strokeColor: AttendanceUiColor.accuracyStroke,
                              fillColor: AttendanceUiColor.accuracyFill,
                              strokeWidth: 1,
                            ),
                        },
                      ),
                    if (previewLocation != null && !_isMapReady)
                      const _MapLoadingOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: const [
                _LegendChip(
                  icon: Icons.business,
                  label: AttendanceUiText.officeLegend,
                  color: AttendanceUiColor.danger,
                ),
                _LegendChip(
                  icon: Icons.my_location,
                  label: AttendanceUiText.youLegend,
                  color: AttendanceUiColor.brandBlue,
                ),
              ],
            ),
            if (widget.currentLocation != null) ...[
              const SizedBox(height: 10),
              _CoordinateText(location: widget.currentLocation!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: widget.isLoading || widget.officeLocation != null
                    ? null
                    : widget.onSetOfficeLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: AttendanceUiColor.brand,
                  disabledBackgroundColor: AttendanceUiColor.btnDisabledBg,
                  disabledForegroundColor: AttendanceUiColor.btnDisabledFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.apartment_rounded, size: 18),
                label: Text(
                  widget.isLoading
                      ? AttendanceUiText.syncingLocation
                      : widget.officeLocation == null
                      ? AttendanceUiText.setOffice
                      : AttendanceUiText.officeSaved,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _currentLocationAccuracyRadius(double? accuracyInMeters) {
    if (accuracyInMeters == null) {
      return 22;
    }

    return accuracyInMeters.clamp(16, 42).toDouble();
  }
}

class _MapLoadingOverlay extends StatelessWidget {
  const _MapLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white70,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 8),
            Text(
              AttendanceUiText.loadingMap,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AttendanceUiColor.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AttendanceUiColor.chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AttendanceUiColor.chipText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinateText extends StatelessWidget {
  const _CoordinateText({required this.location});

  final GeoPoint location;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AttendanceUiColor.coordBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            AttendanceUiText.latLon(
              location.latitude.toStringAsFixed(5),
              location.longitude.toStringAsFixed(5),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AttendanceUiColor.coordText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
