import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AboutNalliqScreen extends StatelessWidget {
  const AboutNalliqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Nalliq'),
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Logo and Title
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 60,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nalliq',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Community Food Barter App',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Mission Section
          _buildSection(
            context,
            'Our Mission',
            'Nalliq connects communities to reduce food waste and build stronger neighborhoods. '
                'We believe that sharing surplus food creates bonds between neighbors while '
                'helping protect our environment.',
          ),

          const SizedBox(height: 24),

          // Features Section
          _buildFeatureSection(context),

          const SizedBox(height: 24),

          // Impact Section
          _buildImpactSection(context),

          const SizedBox(height: 24),

          // Team Section
          _buildSection(
            context,
            'Our Team',
            'Nalliq was created by a passionate team of developers and environmental advocates '
                'based in St. John\'s, Newfoundland and Labrador. We\'re committed to building '
                'technology that makes a positive impact on our communities.',
          ),

          const SizedBox(height: 24),

          // Privacy and Terms
          _buildLegalSection(context),

          const SizedBox(height: 24),

          // Contact Information
          _buildContactSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
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
            const SizedBox(height: 12),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context) {
    final features = [
      {
        'icon': Icons.map,
        'title': 'Local Discovery',
        'description': 'Find food available near you using our interactive map',
      },
      {
        'icon': Icons.camera_alt,
        'title': 'Easy Listing',
        'description': 'Share your surplus food with photos and descriptions',
      },
      {
        'icon': Icons.security,
        'title': 'Trust System',
        'description': 'Build trust through verified exchanges and ratings',
      },
      {
        'icon': Icons.eco,
        'title': 'Eco-Friendly',
        'description': 'Reduce food waste and help the environment',
      },
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => _buildFeatureItem(
                context,
                feature['icon'] as IconData,
                feature['title'] as String,
                feature['description'] as String,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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

  Widget _buildImpactSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Impact',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildImpactStat(
                    context,
                    '1,250+',
                    'Food Items Shared',
                  ),
                ),
                Expanded(
                  child: _buildImpactStat(context, '500+', 'Active Users'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildImpactStat(
                    context,
                    '750 lbs',
                    'Food Waste Prevented',
                  ),
                ),
                Expanded(
                  child: _buildImpactStat(context, '12+', 'Communities Served'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactStat(BuildContext context, String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.privacy_tip,
                color: AppColors.primaryGreen,
              ),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to privacy policy
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.gavel, color: AppColors.primaryGreen),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to terms of service
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code, color: AppColors.primaryGreen),
              title: const Text('Open Source Licenses'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Show licenses dialog
                showLicensePage(context: context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get in Touch',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: AppColors.primaryGreen),
              title: const Text('support@nalliq.com'),
              subtitle: const Text('General inquiries and support'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.web, color: AppColors.primaryGreen),
              title: const Text('www.nalliq.com'),
              subtitle: const Text('Visit our website'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.location_on,
                color: AppColors.primaryGreen,
              ),
              title: const Text('St. John\'s, NL, Canada'),
              subtitle: const Text('Proudly serving Newfoundland and Labrador'),
            ),
          ],
        ),
      ),
    );
  }
}
