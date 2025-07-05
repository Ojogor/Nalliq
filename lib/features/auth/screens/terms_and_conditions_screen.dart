import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  final bool isSignup;
  final VoidCallback? onAccepted;

  const TermsAndConditionsScreen({
    super.key,
    this.isSignup = false,
    this.onAccepted,
  });

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _acceptedTerms = false;
  bool _acceptedSafetyGuidelines = false;
  bool _acceptedDataPolicy = false;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: isDark ? const Color(0xFF2D2D30) : AppColors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppDimensions.marginL),
                  _buildSafetySection(),
                  const SizedBox(height: AppDimensions.marginL),
                  _buildUserRolesSection(),
                  const SizedBox(height: AppDimensions.marginL),
                  _buildFoodSafetySection(),
                  const SizedBox(height: AppDimensions.marginL),
                  _buildLiabilitySection(),
                  const SizedBox(height: AppDimensions.marginL),
                  _buildModerationSection(),
                  const SizedBox(height: AppDimensions.marginL),
                  _buildDataPrivacySection(),
                  const SizedBox(height: AppDimensions.marginL),
                  _buildTerminationSection(),
                ],
              ),
            ),
          ),
          _buildCheckboxes(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nalliq Community Food Sharing',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: AppDimensions.marginM),
        Text(
          'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.marginM),
        _buildWarningBox(),
      ],
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        border: Border.all(color: AppColors.warning, width: 2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'IMPORTANT SAFETY NOTICE',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Food sharing involves inherent risks. By using this app, you acknowledge and accept these risks. Always use your best judgment when sharing or receiving food.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection() {
    return _buildSection('Food Safety & Health Risks', [
      '• Food poisoning and allergic reactions are possible risks',
      '• Users must disclose known allergens and ingredients',
      '• Expired or spoiled food sharing is strictly prohibited',
      '• Users share food at their own risk and discretion',
      '• Nalliq is not responsible for health issues arising from food consumption',
      '• Always inspect food before consumption',
      '• When in doubt, don\'t consume the food',
    ]);
  }

  Widget _buildUserRolesSection() {
    return _buildSection('User Roles & Restrictions', [
      'COMMUNITY MEMBERS:',
      '• Can only share packaged, canned, and shelf-stable items',
      '• Must include expiration dates and ingredient lists',
      '• Cannot share homemade or fresh prepared foods',
      '• Subject to additional safety warnings during transactions',
      '',
      'FRIENDS & VERIFIED USERS:',
      '• Can share any food items including fresh produce and homemade items',
      '• Must still follow all safety guidelines',
      '• Higher trust level enables more sharing options',
      '',
      'FOOD BANKS & ORGANIZATIONS:',
      '• Can share all types of food within regulatory compliance',
      '• Must follow local food safety regulations',
      '• Subject to organizational verification requirements',
    ]);
  }

  Widget _buildFoodSafetySection() {
    return _buildSection('Food Safety Guidelines', [
      '• Check expiration dates before sharing and receiving',
      '• Maintain proper food storage temperatures',
      '• Package food safely to prevent contamination',
      '• Label foods with preparation dates and ingredients',
      '• Disclose all known allergens (nuts, dairy, gluten, etc.)',
      '• Don\'t share food if you\'re ill or have been exposed to illness',
      '• Follow local health department guidelines',
      '• Report any food safety violations through the app',
    ]);
  }

  Widget _buildLiabilitySection() {
    return _buildSection('Liability & Responsibility', [
      '• Users participate in food sharing at their own risk',
      '• Nalliq provides a platform but does not guarantee food safety',
      '• Users are solely responsible for the food they share',
      '• Recipients are responsible for their own health decisions',
      '• Nalliq is not liable for illness, injury, or property damage',
      '• Users agree to hold Nalliq harmless from any claims',
      '• Local laws and regulations take precedence',
    ]);
  }

  Widget _buildModerationSection() {
    return _buildSection('Moderation & Enforcement', [
      '• All listings are subject to moderation and review',
      '• Moderators can remove unsafe listings or ban users',
      '• AI verification helps detect potentially unsafe items',
      '• Users can report violations and safety concerns',
      '• Repeat violations may result in permanent bans',
      '• Community feedback helps maintain safety standards',
      '• Appeals process available for disputed actions',
    ]);
  }

  Widget _buildDataPrivacySection() {
    return _buildSection('Data Privacy & Security', [
      '• Location data used only for nearby food discovery',
      '• Personal information protected according to privacy policy',
      '• Photos and listings may be reviewed by moderators',
      '• Data used for safety verification and fraud prevention',
      '• Users control their own data sharing preferences',
      '• Right to data deletion upon account termination',
    ]);
  }

  Widget _buildTerminationSection() {
    return _buildSection('Account Termination', [
      '• Accounts may be suspended or terminated for violations',
      '• Users can delete their accounts at any time',
      '• Terminated users forfeit all app privileges',
      '• Outstanding food commitments must be honored',
      '• Data retention follows legal requirements',
    ]);
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: AppDimensions.marginM),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxes() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged:
                (value) => setState(() => _acceptedTerms = value ?? false),
            title: const Text(
              'I have read and agree to the Terms & Conditions',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryGreen,
          ),
          CheckboxListTile(
            value: _acceptedSafetyGuidelines,
            onChanged:
                (value) =>
                    setState(() => _acceptedSafetyGuidelines = value ?? false),
            title: const Text(
              'I understand and accept the food safety guidelines and risks',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryGreen,
          ),
          CheckboxListTile(
            value: _acceptedDataPolicy,
            onChanged:
                (value) => setState(() => _acceptedDataPolicy = value ?? false),
            title: const Text(
              'I agree to the data privacy and moderation policies',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final allAccepted =
        _acceptedTerms && _acceptedSafetyGuidelines && _acceptedDataPolicy;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          if (!widget.isSignup) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppDimensions.marginM),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: allAccepted ? _handleAccept : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.isSignup ? 'Continue Registration' : 'Accept'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAccept() async {
    if (widget.isSignup) {
      // For signup flow, call the callback
      widget.onAccepted?.call();
    } else {
      // For viewing terms, update user's terms acceptance
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.acceptTermsAndConditions();

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terms and conditions accepted successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        // Navigate to home since only terms are mandatory
        context.go('/home');
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${authProvider.error ?? 'Failed to accept terms'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
