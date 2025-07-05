import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/report_user_dialog.dart';
import '../../settings/providers/settings_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser profileUser;
  final AppUser currentUser;

  const UserProfileScreen({
    super.key,
    required this.profileUser,
    required this.currentUser,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isFriend = false;
  bool _isLoadingFriendship = false;

  @override
  void initState() {
    super.initState();
    _checkFriendshipStatus();
  }

  void _checkFriendshipStatus() {
    // Check if users are already friends
    _isFriend = widget.currentUser.friendIds.contains(widget.profileUser.id);
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = widget.profileUser.id == widget.currentUser.id;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.profileUser.displayName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isOwnProfile) ...[
            IconButton(
              onPressed: () => _handleMenuAction('message'),
              icon: const Icon(Icons.message, color: Colors.white),
              tooltip: 'Message',
            ),
            IconButton(
              onPressed: () => _handleMenuAction('add_friend'),
              icon: Icon(
                _isFriend ? Icons.person_remove : Icons.person_add,
                color: Colors.white,
              ),
              tooltip: _isFriend ? 'Remove Friend' : 'Add Friend',
            ),
            IconButton(
              onPressed: () => _handleMenuAction('report'),
              icon: const Icon(Icons.report, color: Colors.white),
              tooltip: 'Report User',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [
                    // Profile Picture
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            widget.profileUser.photoUrl != null
                                ? NetworkImage(widget.profileUser.photoUrl!)
                                : null,
                        child:
                            widget.profileUser.photoUrl == null
                                ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      widget.profileUser.displayName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location (if available and visible)
                    if (widget.profileUser.location != null)
                      Consumer<SettingsProvider>(
                        builder: (context, settingsProvider, child) {
                          // For own profile, check settings. For others', always show if they have location
                          final isOwnProfile =
                              widget.profileUser.id == widget.currentUser.id;
                          final shouldShowLocation =
                              isOwnProfile
                                  ? settingsProvider.showLocationToOthers
                                  : true; // Always show other users' locations if they set them

                          return shouldShowLocation
                              ? _buildLocationDisplay()
                              : const SizedBox.shrink();
                        },
                      ),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        _getRoleDisplayName(widget.profileUser.role),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trust Score Card
                  _buildTrustScoreCard(),
                  const SizedBox(height: 20),

                  // Stats Row
                  _buildStatsRow(),
                  const SizedBox(height: 20),

                  // Bio Section
                  if (widget.profileUser.bio != null &&
                      widget.profileUser.bio!.isNotEmpty)
                    _buildBioSection(),

                  // Member Since
                  _buildMemberSinceCard(),
                  const SizedBox(height: 20),

                  // Action Buttons (if not own profile)
                  if (!isOwnProfile) _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScoreCard() {
    final trustScore = widget.profileUser.trustScore;
    final color = _getTrustScoreColor(trustScore);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust Score',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trustScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getTrustScoreLabel(trustScore),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Friends',
            widget.profileUser.friendIds.length.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Items Shared',
            (widget.profileUser.stats['shared'] ?? 0).toString(),
            Icons.share,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Exchanges',
            (widget.profileUser.stats['exchanges'] ?? 0).toString(),
            Icons.swap_horiz,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.profileUser.bio!,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMemberSinceCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              'Member since ${_formatDate(widget.profileUser.createdAt)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoadingFriendship ? null : _toggleFriendship,
                icon:
                    _isLoadingFriendship
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(
                          _isFriend ? Icons.person_remove : Icons.person_add,
                        ),
                label: Text(_isFriend ? 'Remove Friend' : 'Add Friend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFriend ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sendMessage,
                icon: const Icon(Icons.message),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _reportUser,
            icon: const Icon(Icons.report, color: Colors.red),
            label: const Text(
              'Report User',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_friend':
        _toggleFriendship();
        break;
      case 'message':
        _sendMessage();
        break;
      case 'report':
        _reportUser();
        break;
    }
  }

  void _toggleFriendship() async {
    setState(() {
      _isLoadingFriendship = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isFriend = !_isFriend;
      _isLoadingFriendship = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFriend ? 'Friend added!' : 'Friend removed!'),
        backgroundColor: _isFriend ? Colors.green : Colors.orange,
      ),
    );
  }

  void _sendMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening chat...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder:
          (context) => ReportUserDialog(
            reportedUser: widget.profileUser,
            currentUser: widget.currentUser,
          ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.individual:
        return 'Individual';
      case UserRole.foodBank:
        return 'Food Bank';
      case UserRole.communityMember:
        return 'Community Member';
      case UserRole.moderator:
        return 'Moderator';
    }
  }

  Color _getTrustScoreColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getTrustScoreLabel(double score) {
    if (score >= 4.0) return 'Excellent';
    if (score >= 3.0) return 'Good';
    if (score >= 2.0) return 'Fair';
    return 'Poor';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildLocationDisplay() {
    final location = widget.profileUser.location;
    if (location == null) return const SizedBox.shrink();

    final address = location['address'] as String?;
    final city = location['city'] as String?;

    String locationText = '';
    if (address != null && address.isNotEmpty) {
      locationText = address;
    } else if (city != null && city.isNotEmpty) {
      locationText = city;
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            locationText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
