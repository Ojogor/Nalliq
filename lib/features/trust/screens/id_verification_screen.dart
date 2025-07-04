import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/id_verification_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/trust_score_provider.dart';

class IDVerificationScreen extends StatefulWidget {
  const IDVerificationScreen({super.key});

  @override
  State<IDVerificationScreen> createState() => _IDVerificationScreenState();
}

class _IDVerificationScreenState extends State<IDVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();

  IDType _selectedIdType = IDType.driversLicense;
  XFile? _frontImage;
  XFile? _backImage;
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TrustScoreProvider, AuthProvider>(
      builder: (context, trustProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ID Verification'),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  _buildInfoCard(),
                  const SizedBox(height: AppDimensions.marginL),

                  // ID Type Selection
                  _buildSectionHeader('ID Type'),
                  _buildIdTypeSelection(),
                  const SizedBox(height: AppDimensions.marginL),

                  // Image Upload
                  _buildSectionHeader('Upload ID Images'),
                  _buildImageUpload(),
                  const SizedBox(height: AppDimensions.marginL),

                  // Optional Fields
                  _buildSectionHeader('Additional Information (Optional)'),
                  _buildOptionalFields(),
                  const SizedBox(height: AppDimensions.marginL),

                  // Submit Button
                  _buildSubmitButton(trustProvider, authProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.primaryGreen.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            const Icon(Icons.security, size: 48, color: AppColors.primaryGreen),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Verify Your Identity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.marginS),
            const Text(
              'Upload a clear photo of your government-issued ID to verify your identity and boost your trust score by up to 3 points.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Row(
              children: [
                const Icon(Icons.lock, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Your personal information is encrypted and secure',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.marginS),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIdTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children:
              IDType.values.map((type) {
                final verification = IDVerification(
                  id: '',
                  userId: '',
                  idType: type,
                  status: IDVerificationStatus.pending,
                  submittedAt: DateTime.now(),
                );

                return RadioListTile<IDType>(
                  title: Text(verification.displayName),
                  subtitle: Text(
                    'Trust Score: +${verification.scorePoints} points',
                  ),
                  value: type,
                  groupValue: _selectedIdType,
                  onChanged: (value) {
                    setState(() {
                      _selectedIdType = value!;
                    });
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            // Front Image
            _buildImageUploadTile(
              'Front of ID',
              'Upload a clear photo of the front side',
              _frontImage,
              () => _pickImage(true),
              Icons.credit_card,
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Back Image (optional for some ID types)
            if (_selectedIdType == IDType.driversLicense ||
                _selectedIdType == IDType.nationalId)
              _buildImageUploadTile(
                'Back of ID (Optional)',
                'Upload the back side if available',
                _backImage,
                () => _pickImage(false),
                Icons.credit_card,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadTile(
    String title,
    String subtitle,
    XFile? image,
    VoidCallback onTap,
    IconData icon,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primaryGreen),
            const SizedBox(width: AppDimensions.marginM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    image != null ? 'Image selected' : subtitle,
                    style: TextStyle(
                      color: image != null ? AppColors.success : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              image != null ? Icons.check_circle : Icons.add_circle_outline,
              color: image != null ? AppColors.success : AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            // ID Number (last 4 digits)
            TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: 'Last 4 digits of ID (Optional)',
                hintText: 'e.g., 1234',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              maxLength: 4,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Expiry Date
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Expiry Date (Optional)'),
              subtitle: Text(
                _expiryDate != null
                    ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                    : 'Select expiry date',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectExpiryDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) {
    final canSubmit = _frontImage != null && !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            canSubmit
                ? () => _submitVerification(trustProvider, authProvider)
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text('Submit for Verification'),
      ),
    );
  }

  Future<void> _pickImage(bool isFront) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      setState(() {
                        if (isFront) {
                          _frontImage = image;
                        } else {
                          _backImage = image;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        if (isFront) {
                          _frontImage = image;
                        } else {
                          _backImage = image;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitVerification(
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) async {
    if (!_formKey.currentState!.validate() || _frontImage == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await trustProvider.submitIDVerification(
        userId: authProvider.user!.uid,
        idType: _selectedIdType,
        frontImage: _frontImage!,
        backImage: _backImage,
        idNumber:
            _idNumberController.text.isNotEmpty
                ? _idNumberController.text
                : null,
        expiryDate: _expiryDate,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID verification submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trustProvider.error ?? 'Failed to submit verification',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
