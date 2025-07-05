import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/certification_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/trust_score_provider.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final trustProvider = Provider.of<TrustScoreProvider>(
        context,
        listen: false,
      );
      if (authProvider.user != null) {
        trustProvider.loadTrustData(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TrustScoreProvider, AuthProvider>(
      builder: (context, trustProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Food Safety Certifications'),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
          ),
          body:
              trustProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(trustProvider, authProvider),
        );
      },
    );
  }

  Widget _buildContent(
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          _buildInfoCard(),
          const SizedBox(height: AppDimensions.marginL),

          // Current Certifications
          if (trustProvider.certifications.isNotEmpty) ...[
            _buildSectionHeader('Your Certifications'),
            _buildCurrentCertifications(trustProvider.certifications),
            const SizedBox(height: AppDimensions.marginL),
          ],

          // Available Certifications
          _buildSectionHeader('Available Certifications'),
          _buildAvailableCertifications(trustProvider, authProvider),

          const SizedBox(height: AppDimensions.marginL),

          // Test button for development
          _buildTestButton(authProvider),
        ],
      ),
    );
  }

  Widget _buildTestButton(AuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Development Testing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.marginS),
            const Text(
              'For testing purposes, you can mark food safety training as completed without uploading certificates.',
            ),
            const SizedBox(height: AppDimensions.marginM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _markFoodSafetyCompleted(authProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                ),
                child: const Text(
                  'Mark Food Safety Training as Completed (Test)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markFoodSafetyCompleted(AuthProvider authProvider) async {
    try {
      final success = await authProvider.updateFoodSafetyStatus(true);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food safety training marked as completed!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to home since this is the last step
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'Failed to update food safety status',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.primaryGreen.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            const Icon(Icons.school, size: 48, color: AppColors.primaryGreen),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Food Safety Certifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.marginS),
            const Text(
              'Earn trust points by obtaining food safety certifications. Upload your certificates to verify your knowledge and commitment to food safety.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCurrentCertifications(List<FoodCertification> certifications) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: certifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cert = certifications[index];
          return _buildCertificationTile(cert);
        },
      ),
    );
  }

  Widget _buildCertificationTile(FoodCertification cert) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (cert.status) {
      case CertificationStatus.approved:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case CertificationStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
        statusText = 'Pending Review';
        break;
      case CertificationStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case CertificationStatus.expired:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        statusText = 'Expired';
        break;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          cert.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cert.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        trailing:
            cert.status == CertificationStatus.approved
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${cert.scorePoints.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
                : null,
        onTap: () => _showCertificationDetails(cert),
      ),
    );
  }

  Widget _buildAvailableCertifications(
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) {
    final availableTypes = trustProvider.getAvailableCertificationTypes();
    final existingTypes =
        trustProvider.certifications
            .where((cert) => cert.status != CertificationStatus.rejected)
            .map((cert) => cert.type)
            .toSet();

    final availableForSubmission =
        availableTypes.where((type) => !existingTypes.contains(type)).toList();

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: availableForSubmission.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final type = availableForSubmission[index];
          final info = trustProvider.getCertificationInfo(type);

          return Container(
            constraints: const BoxConstraints(minHeight: 72),
            child: ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryGreen,
              ),
              title: Text(
                info['name']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info['description']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trust Score: +${info['points']} points',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _showGetCertificationDialog(type),
                        child: const Text(
                          'Get',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed:
                            () => _showUploadDialog(
                              type,
                              trustProvider,
                              authProvider,
                            ),
                        child: const Text(
                          'Upload',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCertificationDetails(FoodCertification cert) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(cert.displayName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.description),
                const SizedBox(height: 16),
                if (cert.issuer != null) ...[
                  Text('Issuer: ${cert.issuer}'),
                  const SizedBox(height: 8),
                ],
                if (cert.issueDate != null) ...[
                  Text(
                    'Issue Date: ${cert.issueDate!.day}/${cert.issueDate!.month}/${cert.issueDate!.year}',
                  ),
                  const SizedBox(height: 8),
                ],
                if (cert.expiryDate != null) ...[
                  Text(
                    'Expiry Date: ${cert.expiryDate!.day}/${cert.expiryDate!.month}/${cert.expiryDate!.year}',
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Submitted: ${cert.submittedAt.day}/${cert.submittedAt.month}/${cert.submittedAt.year}',
                ),
                if (cert.reviewNotes != null) ...[
                  const SizedBox(height: 8),
                  Text('Review Notes: ${cert.reviewNotes}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showGetCertificationDialog(CertificationType type) {
    final cert = FoodCertification(
      id: '',
      userId: '',
      type: type,
      status: CertificationStatus.pending,
      submittedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Get ${cert.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cert.description),
                const SizedBox(height: 16),
                const Text(
                  'To obtain this certification, you can:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Take an online course'),
                const Text('• Attend a training session'),
                const Text('• Visit a local health department'),
                const Text('• Check with food service organizations'),
                const SizedBox(height: 16),
                Text(
                  'Once you have the certificate, come back and upload it to earn +${cert.scorePoints.toStringAsFixed(1)} trust points!',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void _showUploadDialog(
    CertificationType type,
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) {
    final cert = FoodCertification(
      id: '',
      userId: '',
      type: type,
      status: CertificationStatus.pending,
      submittedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Upload ${cert.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cert.description),
                const SizedBox(height: 16),
                const Text(
                  'Please upload a clear photo or PDF of your certificate. Make sure all text is readable.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  'Trust Score: +${cert.scorePoints.toStringAsFixed(1)} points',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndUploadCertificate(type, trustProvider, authProvider);
                },
                child: const Text('Upload'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickAndUploadCertificate(
    CertificationType type,
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) async {
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
                      _uploadCertificate(
                        type,
                        image,
                        trustProvider,
                        authProvider,
                      );
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
                      _uploadCertificate(
                        type,
                        image,
                        trustProvider,
                        authProvider,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Upload PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    final FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );

                    if (result != null) {
                      final XFile file = XFile(result.files.single.path!);
                      _uploadCertificate(
                        type,
                        file,
                        trustProvider,
                        authProvider,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _uploadCertificate(
    CertificationType type,
    XFile image,
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Uploading certificate...'),
              ],
            ),
          ),
    );

    try {
      final success = await trustProvider.submitFoodCertification(
        userId: authProvider.user!.uid,
        type: type,
        certificateImage: image,
      );

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Certificate uploaded successfully! It will be reviewed soon.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                trustProvider.error ?? 'Failed to upload certificate',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
