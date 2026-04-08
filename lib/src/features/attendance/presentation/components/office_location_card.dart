import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/geo_point.dart';
import '../constants/attendance_ui_color.dart';
import '../constants/attendance_ui_text.dart';

class OfficeLocationCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final previewLocation = officeLocation ?? currentLocation;
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
                if (officeLocation != null)
                  TextButton.icon(
                    onPressed: isLoading ? null : onResetOfficeLocation,
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
              officeLocation == null
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
                child: previewLocation == null
                    ? DecoratedBox(
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
                    : GoogleMap(
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
                          if (officeLocation != null)
                            Marker(
                              markerId: const MarkerId(
                                AttendanceUiText.officeMarkerId,
                              ),
                              position: LatLng(
                                officeLocation!.latitude,
                                officeLocation!.longitude,
                              ),
                              zIndexInt: 1,
                              icon:
                                  officeLocationMarkerIcon ??
                                  BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                              anchor: const Offset(0.5, 1),
                              infoWindow: const InfoWindow(
                                title: AttendanceUiText.officeMarkerTitle,
                              ),
                            ),
                          if (currentLocation != null)
                            Marker(
                              markerId: const MarkerId(
                                AttendanceUiText.currentMarkerId,
                              ),
                              position: LatLng(
                                currentLocation!.latitude,
                                currentLocation!.longitude,
                              ),
                              zIndexInt: 2,
                              icon:
                                  currentLocationMarkerIcon ??
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
                          if (officeLocation != null)
                            Circle(
                              circleId: const CircleId(
                                AttendanceUiText.officeRadiusId,
                              ),
                              center: LatLng(
                                officeLocation!.latitude,
                                officeLocation!.longitude,
                              ),
                              radius: AppConstants.attendanceRadiusInMeters,
                              strokeColor: AttendanceUiColor.danger,
                              fillColor: AttendanceUiColor.officeRadiusFill,
                              strokeWidth: 2,
                            ),
                          if (currentLocation != null)
                            Circle(
                              circleId: const CircleId(
                                AttendanceUiText.currentAccuracyId,
                              ),
                              center: LatLng(
                                currentLocation!.latitude,
                                currentLocation!.longitude,
                              ),
                              radius: _currentLocationAccuracyRadius(
                                currentLocation!.accuracyInMeters,
                              ),
                              strokeColor: AttendanceUiColor.accuracyStroke,
                              fillColor: AttendanceUiColor.accuracyFill,
                              strokeWidth: 1,
                            ),
                        },
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
            if (currentLocation != null) ...[
              const SizedBox(height: 10),
              _CoordinateText(location: currentLocation!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: isLoading || officeLocation != null
                    ? null
                    : onSetOfficeLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: AttendanceUiColor.brand,
                  disabledBackgroundColor: AttendanceUiColor.btnDisabledBg,
                  disabledForegroundColor: AttendanceUiColor.btnDisabledFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.apartment_rounded, size: 18),
                label: Text(
                  isLoading
                      ? AttendanceUiText.syncingLocation
                      : officeLocation == null
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
