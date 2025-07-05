import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapThumbnail extends StatelessWidget {
  final LatLng location;

  const MapThumbnail({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: location, zoom: 15),
        markers: {
          Marker(markerId: const MarkerId('location'), position: location),
        },
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
