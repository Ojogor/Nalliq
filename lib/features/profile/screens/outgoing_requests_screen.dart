import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';

class OutgoingRequestsScreen extends StatefulWidget {
  const OutgoingRequestsScreen({super.key});

  @override
  State<OutgoingRequestsScreen> createState() => _OutgoingRequestsScreenState();
}

class _OutgoingRequestsScreenState extends State<OutgoingRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<ExchangeRequest> _outgoingRequests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOutgoingRequests();
  }

  Future<void> _loadOutgoingRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not authenticated';
        });
        return;
      }

      final query =
          await _firestore
              .collection('exchange_requests')
              .where('requesterId', isEqualTo: authProvider.user!.uid)
              .orderBy('createdAt', descending: true)
              .get();

      final requests =
          query.docs.map((doc) => ExchangeRequest.fromFirestore(doc)).toList();

      setState(() {
        _outgoingRequests = requests;
        _isLoading = false;
      });

      print('Loaded ${requests.length} outgoing requests'); // Debug logging
    } catch (e) {
      print('Error loading outgoing requests: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRequest(ExchangeRequest request) async {
    try {
      await _firestore.collection('exchange_requests').doc(request.id).update({
        'status': RequestStatus.cancelled.name,
      });

      // Reload the requests
      _loadOutgoingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled!'),
          backgroundColor: AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outgoing Requests'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOutgoingRequests,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadOutgoingRequests,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: AppDimensions.marginL),
          Text(
            'Error loading requests',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.marginM),
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.marginL),
          ElevatedButton(
            onPressed: _loadOutgoingRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_outgoingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.outbox_outlined, size: 80, color: AppColors.grey),
            const SizedBox(height: AppDimensions.marginL),
            Text(
              'No outgoing requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Requests you\'ve sent to others will appear here.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _outgoingRequests.length,
      itemBuilder: (context, index) {
        final request = _outgoingRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(ExchangeRequest request) {
    Color statusColor;
    String statusText;

    switch (request.status) {
      case RequestStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Pending';
        break;
      case RequestStatus.accepted:
        statusColor = AppColors.success;
        statusText = 'Accepted';
        break;
      case RequestStatus.declined:
        statusColor = AppColors.error;
        statusText = 'Declined';
        break;
      case RequestStatus.completed:
        statusColor = AppColors.success;
        statusText = 'Completed';
        break;
      case RequestStatus.cancelled:
        statusColor = AppColors.grey;
        statusText = 'Cancelled';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Request to ${request.ownerId}', // TODO: Get actual user name
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginS),
            Text(
              'Requested Items: ${request.requestedItemIds.join(", ")}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (request.offeredItemIds.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.marginS),
              Text(
                'Offered Items: ${request.offeredItemIds.join(", ")}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.marginS),
              Text(
                'Message: ${request.message}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: AppDimensions.marginS),
            Text(
              'Sent: ${_formatDate(request.createdAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (request.status == RequestStatus.pending) ...[
              const SizedBox(height: AppDimensions.marginM),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _cancelRequest(request),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
