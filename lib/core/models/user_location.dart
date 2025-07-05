import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserLocation {
  final String? address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? province;
  final String? country;
  final bool isVisible;
  final DateTime? lastUpdated;

  const UserLocation({
    this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.province,
    this.country,
    this.isVisible = true,
    this.lastUpdated,
  });

  // Default St. John's, Newfoundland location
  static const UserLocation defaultLocation = UserLocation(
    address: "St. John's, NL, Canada",
    latitude: 47.5615,
    longitude: -52.7126,
    city: "St. John's",
    province: "Newfoundland and Labrador",
    country: "Canada",
    isVisible: true,
  );

  LatLng get coordinates => LatLng(latitude, longitude);

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      address: json['address'],
      latitude: (json['latitude'] ?? 47.5615).toDouble(),
      longitude: (json['longitude'] ?? -52.7126).toDouble(),
      city: json['city'],
      province: json['province'],
      country: json['country'],
      isVisible: json['isVisible'] ?? true,
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'province': province,
      'country': country,
      'isVisible': isVisible,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  UserLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? city,
    String? province,
    String? country,
    bool? isVisible,
    DateTime? lastUpdated,
  }) {
    return UserLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      isVisible: isVisible ?? this.isVisible,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return address ?? '$city, $province, $country';
  }
}
