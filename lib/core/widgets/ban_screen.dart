import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/moderation_service.dart';

class BanScreen extends StatelessWidget {
  final AppUser user;

  const BanScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final banMessage = ModerationService.getBanMessage(user);

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ban icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.block, size: 60, color: Colors.red.shade600),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Account Suspended',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Ban message
              Text(
                banMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Information card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Account Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('User ID', user.id),
                    _buildInfoRow('Email', user.email),
                    if (user.banDate != null)
                      _buildInfoRow('Banned on', _formatDate(user.banDate!)),
                    _buildInfoRow(
                      'Trust Score',
                      user.trustScore.toStringAsFixed(1),
                    ),
                    _buildInfoRow('Reports', user.reportCount.toString()),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Contact support button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _contactSupport(context),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign out button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _contactSupport(BuildContext context) {
    // TODO: Implement contact support functionality
    // This could open an email client, launch a support URL, or navigate to a support form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact support at: support@nalliq.com'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _signOut(BuildContext context) {
    // TODO: Implement sign out functionality
    // This should clear user session and navigate to login screen
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement actual sign out logic
                  Navigator.of(context).pop();
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }
}
