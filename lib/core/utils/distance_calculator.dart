import 'dart:math';

class DistanceCalculator {
  /// Calculate the distance between two points on Earth using the Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert degrees to radians
    double lat1Rad = lat1 * pi / 180;
    double lon1Rad = lon1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double lon2Rad = lon2 * pi / 180;

    // Calculate differences
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;

    // Haversine formula
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  /// Calculate distance between current user and a store/user
  /// Returns null if either location is not available
  static double? calculateDistanceToUser(
    Map<String, dynamic>? currentUserLocation,
    Map<String, dynamic>? targetUserLocation,
  ) {
    if (currentUserLocation == null || targetUserLocation == null) {
      return null;
    }

    final currentLat = currentUserLocation['latitude']?.toDouble();
    final currentLng = currentUserLocation['longitude']?.toDouble();
    final targetLat = targetUserLocation['latitude']?.toDouble();
    final targetLng = targetUserLocation['longitude']?.toDouble();

    if (currentLat == null ||
        currentLng == null ||
        targetLat == null ||
        targetLng == null) {
      return null;
    }

    return calculateDistance(currentLat, currentLng, targetLat, targetLng);
  }
}
