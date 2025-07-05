import 'package:flutter/material.dart';

class DistanceWidget extends StatelessWidget {
  final double distanceInKm;
  final IconData? icon;
  final Color? color;

  const DistanceWidget({
    super.key,
    required this.distanceInKm,
    this.icon,
    this.color,
  });

  String _formatDistance() {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m away';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km away';
    } else {
      return '${distanceInKm.round()}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon ?? Icons.location_on,
          size: 14,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          _formatDistance(),
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600]),
        ),
      ],
    );
  }
}
