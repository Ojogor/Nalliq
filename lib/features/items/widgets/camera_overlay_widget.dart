import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class CameraOverlayWidget extends StatefulWidget {
  final int requiredPhotos;
  final List<String> photoLabels;
  final Function(List<File>) onPhotosComplete;

  const CameraOverlayWidget({
    super.key,
    required this.requiredPhotos,
    required this.photoLabels,
    required this.onPhotosComplete,
  });

  @override
  State<CameraOverlayWidget> createState() => _CameraOverlayWidgetState();
}

class _CameraOverlayWidgetState extends State<CameraOverlayWidget> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentPhotoIndex = 0;
  List<File> _capturedPhotos = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        debugPrint('No cameras available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras available on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 16),
              const Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _initializeCamera,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(child: CameraPreview(_controller!)),

        // Overlay with guidelines
        _buildOverlay(),

        // Top info panel
        _buildTopPanel(),

        // Bottom controls
        _buildBottomControls(),

        // Photo thumbnails
        _buildPhotoThumbnails(),
      ],
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryGreen, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Corner guides
                Expanded(
                  child: Stack(
                    children: [
                      // Top-left corner
                      Positioned(top: 10, left: 10, child: _buildCornerGuide()),
                      // Top-right corner
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Transform.rotate(
                          angle: 1.5708, // 90 degrees
                          child: _buildCornerGuide(),
                        ),
                      ),
                      // Bottom-left corner
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Transform.rotate(
                          angle: -1.5708, // -90 degrees
                          child: _buildCornerGuide(),
                        ),
                      ),
                      // Bottom-right corner
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Transform.rotate(
                          angle: 3.1416, // 180 degrees
                          child: _buildCornerGuide(),
                        ),
                      ),
                      // Center guidelines based on photo type
                      if (_currentPhotoIndex == 2) // Barcode photo
                        Center(
                          child: Container(
                            width: 200,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.warning,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Align barcode here',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerGuide() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primaryGreen, width: 3),
          left: BorderSide(color: AppColors.primaryGreen, width: 3),
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Text(
                'Photo ${_currentPhotoIndex + 1} of ${widget.requiredPhotos}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentPhotoIndex < widget.photoLabels.length
                    ? widget.photoLabels[_currentPhotoIndex]
                    : 'Additional photo',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Retake button (if photos taken)
              if (_capturedPhotos.isNotEmpty)
                IconButton(
                  onPressed: _retakePhoto,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

              // Capture button
              GestureDetector(
                onTap: _capturePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primaryGreen, width: 4),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryGreen,
                    size: 40,
                  ),
                ),
              ),

              // Skip button (for optional photos)
              if (_currentPhotoIndex >= widget.requiredPhotos)
                TextButton(
                  onPressed: _skipPhoto,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

              // Complete button (if minimum photos taken)
              if (_capturedPhotos.length >= widget.requiredPhotos)
                TextButton(
                  onPressed: _completePhotos,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnails() {
    if (_capturedPhotos.isEmpty) return const SizedBox();

    return Positioned(
      right: 16,
      top: 120,
      child: Column(
        children:
            _capturedPhotos.asMap().entries.map((entry) {
              final photo = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    photo,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile photo = await _controller!.takePicture();
      final File photoFile = File(photo.path);

      setState(() {
        _capturedPhotos.add(photoFile);
        _currentPhotoIndex++;
      });

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // If all required photos are taken, show completion option
      if (_capturedPhotos.length >= widget.requiredPhotos) {
        // Auto-advance after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (_currentPhotoIndex >= widget.requiredPhotos) {
          _completePhotos();
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing photo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _retakePhoto() {
    if (_capturedPhotos.isNotEmpty) {
      setState(() {
        _capturedPhotos.removeLast();
        _currentPhotoIndex--;
      });
    }
  }

  void _skipPhoto() {
    setState(() {
      _currentPhotoIndex++;
    });
  }

  void _completePhotos() {
    if (_capturedPhotos.length >= widget.requiredPhotos) {
      widget.onPhotosComplete(_capturedPhotos);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
