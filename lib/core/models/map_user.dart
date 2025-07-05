import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUser {
  final String id;
  final String name;
  final String profileImageUrl;
  final LatLng location;
  final bool isLocationVisible;
  final double? distanceFromCurrentUser;

  MapUser({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.location,
    required this.isLocationVisible,
    this.distanceFromCurrentUser,
  });
}
