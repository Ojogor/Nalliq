import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/food_item_model.dart';
import '../../../core/services/location_service.dart';

class LocationNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Handle notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to item details
    print('Notification tapped: ${response.payload}');
  }

  /// Show location-based alert for new food item
  static Future<void> showLocationAlert(FoodItem item, double distance) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'location_alerts',
      'Location Alerts',
      channelDescription: 'Notifications for nearby food items',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final distanceText = LocationService.getDistanceText(distance);

    await _notifications.show(
      item.hashCode, // Use item hash as unique ID
      'New Food Item Nearby! 📍',
      '${item.name} is available $distanceText from you',
      details,
      payload: item.id,
    );
  }

  /// Setup listener for new items and check location alerts
  static StreamSubscription<QuerySnapshot>? _itemsSubscription;

  static void startLocationAlertsListener({
    required String currentUserId,
    required Map<String, dynamic>? userLocation,
    required double alertRadius,
    required bool alertsEnabled,
  }) {
    if (!alertsEnabled || userLocation == null) {
      stopLocationAlertsListener();
      return;
    }

    // Listen to new items
    _itemsSubscription = FirebaseFirestore.instance
        .collection('items')
        .where('status', isEqualTo: 'available')
        .where(
          'ownerId',
          isNotEqualTo: currentUserId,
        ) // Don't alert for own items
        .orderBy('ownerId') // Required for inequality filter
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to recent items
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final item = FoodItem.fromFirestore(change.doc);
              _checkAndSendLocationAlert(item, userLocation, alertRadius);
            }
          }
        });
  }

  static void stopLocationAlertsListener() {
    _itemsSubscription?.cancel();
    _itemsSubscription = null;
  }

  static void _checkAndSendLocationAlert(
    FoodItem item,
    Map<String, dynamic> userLocation,
    double alertRadius,
  ) {
    if (item.location == null) return;

    final isWithinRadius = LocationService.isWithinRadius(
      item.location,
      userLocation,
      alertRadius,
    );

    if (isWithinRadius) {
      final distance = LocationService.calculateDistance(
        userLocation['lat'] as double,
        userLocation['lng'] as double,
        item.location!['lat'] as double,
        item.location!['lng'] as double,
      );

      showLocationAlert(item, distance);
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    await initialize();

    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    await initialize();

    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }

    return true; // Assume enabled on other platforms
  }

  /// Cancel all location alert notifications
  static Future<void> cancelAllLocationAlerts() async {
    await _notifications.cancelAll();
  }
}
