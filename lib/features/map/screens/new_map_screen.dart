import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nalliq/core/models/user_location.dart';
import 'package:provider/provider.dart';

import '../../../core/services/firebase_location_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../location/providers/new_location_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {}; // Make non-final to allow updates
  bool _isLoading = true; // Initialize to true
  StreamSubscription<List<MapUser>>? _nearbyUsersSubscription;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToNearbyUsers();
    });
  }

  @override
  void dispose() {
    _nearbyUsersSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _subscribeToNearbyUsers() {
    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AuthProvider>();

    // Start initial load
    _loadMapData(locationProvider);

    // Subscribe to stream for real-time updates
    _nearbyUsersSubscription = locationProvider.nearbyUsersStream.listen(
      (users) {
        _createMarkers(
          users,
          locationProvider.currentLocation,
          authProvider.user?.uid,
        );
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting user updates: $error')),
          );
        }
      },
    );
  }

  Future<void> _loadMapData(LocationProvider locationProvider) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await locationProvider.loadCurrentLocation();
      // Initial fetch, stream will handle subsequent updates
      await locationProvider.loadNearbyUsers();

      print('🗺️ Map data loaded:');
      print('  Current location: ${locationProvider.currentLocation?.address}');
      print('  Nearby users count: ${locationProvider.nearbyUsers.length}');

      final currentLocation = locationProvider.currentLocation;
      if (_mapController != null && currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation.coordinates, 14.0),
        );
      }
    } catch (e) {
      print('❌ Error loading map data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading map data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createMarkers(
    List<MapUser> users,
    UserLocation? currentUserLocation,
    String? currentUserId,
  ) async {
    if (!mounted) return;

    print('🔍 Creating markers for ${users.length} users');
    print('📍 Current user ID: $currentUserId');
    print(
      '📍 Users in list: ${users.map((u) => '${u.name} (${u.id})').join(', ')}',
    );

    Set<Marker> markers = {};

    // Add a special marker for the current user's exact location
    if (currentUserLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('currentUser'),
          position: currentUserLocation.coordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: const InfoWindow(title: 'Your Location'),
          zIndex: 2, // Ensure it's on top
        ),
      );
      print(
        '✅ Added current user marker at ${currentUserLocation.coordinates}',
      );
    }

    int otherUsersCount = 0;
    for (final user in users) {
      // Skip adding a regular marker for the current user
      if (user.id == currentUserId) {
        print('⏭️ Skipping current user: ${user.name}');
        continue;
      }

      otherUsersCount++;

      final obfuscatedPosition = _obfuscateCoordinates(
        user.location.coordinates,
      );

      final distance =
          currentUserLocation != null
              ? FirebaseLocationService.calculateDistance(
                currentUserLocation,
                user.location,
              )
              : null;
      final snippetText =
          distance != null ? '${distance.toStringAsFixed(1)} km away' : '';

      final icon = await _createCustomMarker(
        user.profilePictureUrl,
        user.name.isNotEmpty ? user.name[0] : ' ',
      );

      markers.add(
        Marker(
          markerId: MarkerId(user.id),
          position: obfuscatedPosition,
          icon: icon,
          infoWindow: InfoWindow(
            title: user.name,
            snippet: snippetText,
            onTap: () => context.push('/home/store/${user.id}'),
          ),
          onTap: () => context.push('/home/store/${user.id}'),
        ),
      );

      print('✅ Added marker for user: ${user.name} at ${obfuscatedPosition}');
    }

    print('👥 Other users processed: $otherUsersCount');

    if (mounted) {
      setState(() {
        _markers = markers;
      });
      print('🎯 Total markers set: ${markers.length}');
    }
  }

  // Helper to obfuscate coordinates for privacy
  LatLng _obfuscateCoordinates(LatLng original) {
    final random = Random();
    // Offset creates a radius of ~150-250 meters
    const double offset = 0.002;
    final latOffset = (random.nextDouble() - 0.5) * offset * 2;
    final lngOffset = (random.nextDouble() - 0.5) * offset * 2;
    return LatLng(
      original.latitude + latOffset,
      original.longitude + lngOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Map'),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              // Data loading is now initiated from initState
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(47.5615, -52.7126), // St. John's, NL
              zoom: 12.0,
            ),
            markers: _markers,
            myLocationEnabled: false, // Disabled to avoid permission errors
            myLocationButtonEnabled: false, // We'll use our custom button
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // My Location Button (Top Right, below profile)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: FloatingActionButton(
              heroTag: "map_my_location_fab",
              mini: true,
              onPressed: () async {
                if (_mapController != null &&
                    locationProvider.currentLocation != null) {
                  await _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      locationProvider.currentLocation!.coordinates,
                      14.0,
                    ),
                  );
                }
              },
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Profile Button (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: FloatingActionButton(
              heroTag: "map_profile_fab",
              mini: true,
              onPressed: () {
                context.push('/profile');
              },
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              child: const Icon(Icons.person),
            ),
          ),

          // Refresh Button (Top Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: FloatingActionButton(
              heroTag: "map_refresh_fab",
              mini: true,
              onPressed: () => _loadMapData(locationProvider),
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }

  Future<BitmapDescriptor> _createCustomMarker(
    String? imageUrl,
    String initial,
  ) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      const double size = 150.0;
      const double borderSize = 10.0;
      const double imageSize = size - (borderSize * 2);

      // Define paints
      final Paint borderPaint =
          Paint()
            ..color = Colors.blueAccent
            ..style = PaintingStyle.fill;

      final Paint backgroundPaint = Paint()..color = Colors.white;

      // Draw border circle
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        borderPaint,
      );
      // Draw background circle for the image
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        (size / 2) - borderSize,
        backgroundPaint,
      );

      // Try to load and draw the network image
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final Completer<ui.Image> completer = Completer();
          final imageProvider = CachedNetworkImageProvider(imageUrl);

          final listener = ImageStreamListener((ImageInfo imageInfo, bool _) {
            if (!completer.isCompleted) {
              completer.complete(imageInfo.image);
            }
          });

          imageProvider
              .resolve(const ImageConfiguration())
              .addListener(listener);

          final ui.Image image = await completer.future.timeout(
            const Duration(seconds: 10),
          );

          // Clip to circle and draw the image
          final Path clipPath = Path();
          clipPath.addOval(
            Rect.fromCircle(
              center: const Offset(size / 2, size / 2),
              radius: imageSize / 2,
            ),
          );
          canvas.clipPath(clipPath);

          paintImage(
            canvas: canvas,
            rect: Rect.fromLTWH(borderSize, borderSize, imageSize, imageSize),
            image: image,
            fit: BoxFit.cover,
          );
        } catch (e) {
          // If image loading fails, draw the initial
          _drawInitial(canvas, initial, size);
        }
      } else {
        // If no image URL, draw the initial
        _drawInitial(canvas, initial, size);
      }

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image finalImage = await picture.toImage(
        size.toInt(),
        size.toInt(),
      );
      final ByteData? byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      print('Error creating custom marker: $e');
    }

    return BitmapDescriptor.defaultMarker; // Ultimate fallback
  }

  void _drawInitial(Canvas canvas, String initial, double size) {
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: initial.toUpperCase(),
      style: const TextStyle(
        fontSize: 70,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );
  }
}
