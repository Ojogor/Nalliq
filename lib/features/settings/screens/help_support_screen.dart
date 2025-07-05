import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // FAQ Section
          _buildSection(context, 'Frequently Asked Questions', [
            _buildFAQItem(
              context,
              'How do I create a listing?',
              'Tap the + button on the home screen, add photos of your food items, set your preferences, and publish your listing.',
            ),
            _buildFAQItem(
              context,
              'How do I find food near me?',
              'Use the map view to see available food items in your area. You can filter by distance, category, and user type.',
            ),
            _buildFAQItem(
              context,
              'How does the trust score work?',
              'Your trust score increases when you complete successful exchanges, verify your identity, and receive positive ratings from other users.',
            ),
            _buildFAQItem(
              context,
              'How do I contact another user?',
              'Tap on their listing and use the contact button to send them a message or exchange request.',
            ),
            _buildFAQItem(
              context,
              'What should I do if I have a safety concern?',
              'Report any safety concerns using the report button on user profiles or listings. We take all reports seriously.',
            ),
          ]),

          const SizedBox(height: 24),

          // Contact Support Section
          _buildSection(context, 'Contact Support', [
            _buildContactOption(
              context,
              Icons.email,
              'Email Support',
              'support@nalliq.com',
              () => _launchEmail('support@nalliq.com'),
            ),
            _buildContactOption(
              context,
              Icons.phone,
              'Phone Support',
              '+1 (709) 555-FOOD',
              () => _launchPhone('+17095553663'),
            ),
            _buildContactOption(
              context,
              Icons.chat,
              'Live Chat',
              'Available 9 AM - 5 PM EST',
              () => _showLiveChatInfo(context),
            ),
          ]),

          const SizedBox(height: 24),

          // Safety Guidelines Section
          _buildSection(context, 'Safety Guidelines', [
            _buildSafetyTip(
              context,
              Icons.security,
              'Meet in Public Places',
              'Always arrange to meet in well-lit, public locations for exchanges.',
            ),
            _buildSafetyTip(
              context,
              Icons.group,
              'Bring a Friend',
              'Consider bringing a friend or family member to exchanges.',
            ),
            _buildSafetyTip(
              context,
              Icons.schedule,
              'Verify Food Quality',
              'Check expiration dates and food quality before accepting items.',
            ),
            _buildSafetyTip(
              context,
              Icons.report,
              'Report Issues',
              'Report any suspicious behavior or safety concerns immediately.',
            ),
          ]),

          const SizedBox(height: 24),

          // Community Guidelines
          _buildSection(context, 'Community Guidelines', [
            _buildGuidelineItem(
              context,
              'Be respectful and kind to all community members',
            ),
            _buildGuidelineItem(
              context,
              'Only share food that is safe to consume',
            ),
            _buildGuidelineItem(
              context,
              'Provide accurate descriptions and photos',
            ),
            _buildGuidelineItem(context, 'Follow through on your commitments'),
            _buildGuidelineItem(context, 'Report inappropriate behavior'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSafetyTip(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(BuildContext context, String guideline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(guideline)),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email address $email copied to clipboard')),
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number $phone copied to clipboard')),
      );
    }
  }

  void _showLiveChatInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Live Chat'),
            content: const Text(
              'Live chat is available Monday through Friday, 9 AM to 5 PM EST. '
              'For immediate assistance outside these hours, please use email support.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
