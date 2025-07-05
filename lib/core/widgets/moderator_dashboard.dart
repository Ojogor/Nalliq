import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_report_model.dart';
import '../services/moderation_service.dart';

class ModeratorDashboard extends StatefulWidget {
  final AppUser currentUser;

  const ModeratorDashboard({Key? key, required this.currentUser})
    : super(key: key);

  @override
  State<ModeratorDashboard> createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is moderator
    if (!widget.currentUser.isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Moderator Access Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have permission to access this area.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderator Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Reports', icon: Icon(Icons.report)),
            Tab(text: 'User Management', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingReportsTab(currentUser: widget.currentUser),
          _UserManagementTab(currentUser: widget.currentUser),
        ],
      ),
    );
  }
}

class _PendingReportsTab extends StatelessWidget {
  final AppUser currentUser;

  const _PendingReportsTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserReport>>(
      stream: ModerationService.getPendingReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No Pending Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'All reports have been reviewed.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _ReportCard(
              report: report,
              currentUser: currentUser,
              onReportResolved: () {
                // Refresh will happen automatically due to stream
              },
            );
          },
        );
      },
    );
  }
}

class _UserManagementTab extends StatelessWidget {
  final AppUser currentUser;

  const _UserManagementTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'User Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text('Coming soon...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final UserReport report;
  final AppUser currentUser;
  final VoidCallback onReportResolved;

  const _ReportCard({
    required this.report,
    required this.currentUser,
    required this.onReportResolved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reasonDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported ${_formatDate(report.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.statusDisplayName,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Report details
            _buildInfoRow('Reported User ID', report.reportedUserId),
            _buildInfoRow('Reporter ID', report.reporterId),
            if (report.relatedItemId != null)
              _buildInfoRow('Related Item', report.relatedItemId!),

            const SizedBox(height: 12),

            // Description
            if (report.description.isNotEmpty) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                report.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        () => _resolveReport(
                          context,
                          report,
                          ReportStatus.dismissed,
                        ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        () => _resolveReport(
                          context,
                          report,
                          ReportStatus.resolved,
                        ),
                    child: const Text('Resolve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resolveReport(
    BuildContext context,
    UserReport report,
    ReportStatus status,
  ) async {
    final TextEditingController notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${status == ReportStatus.resolved ? 'Resolve' : 'Dismiss'} Report',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to ${status == ReportStatus.resolved ? 'resolve' : 'dismiss'} this report?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Moderator Notes',
                    hintText: 'Add notes about your decision...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  status == ReportStatus.resolved ? 'Resolve' : 'Dismiss',
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await ModerationService.resolveReport(
        reportId: report.id,
        moderatorId: currentUser.id,
        newStatus: status,
        moderatorNotes: notesController.text.trim(),
      );

      if (success) {
        onReportResolved();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Report ${status == ReportStatus.resolved ? 'resolved' : 'dismissed'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update report'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    notesController.dispose();
  }
}
