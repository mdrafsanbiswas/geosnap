import 'package:flutter/material.dart';

class ZoomRail extends StatelessWidget {
  const ZoomRail({
    required this.minZoom,
    required this.maxZoom,
    required this.currentZoom,
    required this.onChanged,
    super.key,
  });

  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: SizedBox(
        width: 180,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: currentZoom.clamp(minZoom, maxZoom),
            min: minZoom,
            max: maxZoom,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
