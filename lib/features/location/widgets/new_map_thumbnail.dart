import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/user_location.dart';

class MapThumbnail extends StatelessWidget {
  final UserLocation location;

  const MapThumbnail({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: location.coordinates,
            zoom: 15.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('current_location'),
              position: location.coordinates,
              infoWindow: InfoWindow(
                title: 'Your Location',
                snippet: location.toString(),
              ),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
      ),
    );
  }
}
