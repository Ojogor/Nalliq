import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const BarcodeScannerWidget({super.key, required this.onBarcodeScanned});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR_Widget');
  QRViewController? controller;
  bool _isScanning = true;
  bool _flashOn = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode/QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {
                _flashOn = !_flashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () async {
              await controller?.flipCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner view
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColors.primaryGreen,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 4,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),

          // Instructions
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Position the barcode or QR code within the frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTipItem(Icons.center_focus_strong, 'Center'),
                _buildTipItem(Icons.wb_sunny, 'Good Light'),
                _buildTipItem(Icons.zoom_out, 'Steady Hold'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isScanning) return;

      final String? code = scanData.code;

      if (code != null && code.isNotEmpty) {
        _isScanning = false;

        // Provide haptic feedback
        HapticFeedback.selectionClick();

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode scanned: $code'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );

        // Return the scanned code
        widget.onBarcodeScanned(code);

        // Close the scanner after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
