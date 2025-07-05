import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_report_model.dart';
import '../services/moderation_service.dart';

class ReportUserDialog extends StatefulWidget {
  final AppUser reportedUser;
  final AppUser currentUser;
  final String? relatedItemId;

  const ReportUserDialog({
    super.key,
    required this.reportedUser,
    required this.currentUser,
    this.relatedItemId,
  });

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.reportedUser.displayName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this user?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Reason selection
            ...ReportReason.values.map(
              (reason) => RadioListTile<ReportReason>(
                title: Text(reason.displayName),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Additional details',
                hintText:
                    'Please provide more information about your report...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),

            const SizedBox(height: 8),

            // Warning text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'False reports may result in penalties to your account.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _isSubmitting || _selectedReason == null ? null : _submitReport,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Submit Report'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ModerationService.reportUser(
        reporterId: widget.currentUser.id,
        reportedUserId: widget.reportedUser.id,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        relatedItemId: widget.relatedItemId,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit report. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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

extension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.scam:
        return 'Scam or Fraud';
      case ReportReason.unsafeFood:
        return 'Unsafe Food Item';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.fakeProfile:
        return 'Fake Profile';
      case ReportReason.other:
        return 'Other';
    }
  }
}
