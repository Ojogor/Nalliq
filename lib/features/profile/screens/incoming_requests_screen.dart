import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<ExchangeRequest> _incomingRequests = [];
  String? _error;
  Map<String, String> _userDisplayNames = {}; // Cache for user display names
  Map<String, String> _itemNames = {}; // Cache for item names

  @override
  void initState() {
    super.initState();
    _loadIncomingRequests();
  }

  Future<void> _loadIncomingRequests() async {
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
              .where('ownerId', isEqualTo: authProvider.user!.uid)
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .get();

      final requests =
          query.docs.map((doc) => ExchangeRequest.fromFirestore(doc)).toList();

      setState(() {
        _incomingRequests = requests;
        _isLoading = false;
      });

      print('Loaded ${requests.length} incoming requests'); // Debug logging
    } catch (e) {
      print('Error loading incoming requests: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToRequest(
    ExchangeRequest request,
    RequestStatus newStatus,
  ) async {
    try {
      await _firestore.collection('exchange_requests').doc(request.id).update({
        'status': newStatus.name,
        'respondedAt': Timestamp.now(),
      });

      // Reload the requests
      _loadIncomingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == RequestStatus.accepted
                ? 'Request accepted!'
                : 'Request declined!',
          ),
          backgroundColor:
              newStatus == RequestStatus.accepted
                  ? AppColors.success
                  : AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<String> _getUserDisplayName(String userId) async {
    // Check cache first
    if (_userDisplayNames.containsKey(userId)) {
      return _userDisplayNames[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final displayName =
            userData['displayName'] ?? userData['email'] ?? 'Unknown User';
        _userDisplayNames[userId] = displayName;
        return displayName;
      } else {
        _userDisplayNames[userId] = 'Unknown User';
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user display name for $userId: $e');
      _userDisplayNames[userId] = 'Unknown User';
      return 'Unknown User';
    }
  }

  Future<String> _getItemName(String itemId) async {
    // Check cache first
    if (_itemNames.containsKey(itemId)) {
      return _itemNames[itemId]!;
    }

    try {
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (itemDoc.exists) {
        final itemData = itemDoc.data() as Map<String, dynamic>;
        final itemName = itemData['name'] ?? 'Unknown Item';
        _itemNames[itemId] = itemName;
        return itemName;
      } else {
        _itemNames[itemId] = 'Unknown Item';
        return 'Unknown Item';
      }
    } catch (e) {
      print('Error fetching item name for $itemId: $e');
      _itemNames[itemId] = 'Unknown Item';
      return 'Unknown Item';
    }
  }

  Future<String> _getItemNames(List<String> itemIds) async {
    if (itemIds.isEmpty) return 'None';

    final names = await Future.wait(itemIds.map((id) => _getItemName(id)));
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncomingRequests,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadIncomingRequests,
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
            onPressed: _loadIncomingRequests,
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
    if (_incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: AppColors.grey),
            const SizedBox(height: AppDimensions.marginL),
            Text(
              'No incoming requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Requests for your food items will appear here.',
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
      itemCount: _incomingRequests.length,
      itemBuilder: (context, index) {
        final request = _incomingRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(ExchangeRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginM),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'barter-detail',
            pathParameters: {'requestId': request.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _getUserDisplayName(request.requesterId),
                      builder: (context, snapshot) {
                        final displayName = snapshot.data ?? 'Loading...';
                        return Text(
                          'Request from $displayName',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.marginS),
              FutureBuilder<String>(
                future: _getItemNames(request.requestedItemIds),
                builder: (context, snapshot) {
                  final itemNames = snapshot.data ?? 'Loading...';
                  return Text(
                    'Requested Items: $itemNames',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
              ),
              if (request.offeredItemIds.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.marginS),
                FutureBuilder<String>(
                  future: _getItemNames(request.offeredItemIds),
                  builder: (context, snapshot) {
                    final itemNames = snapshot.data ?? 'Loading...';
                    return Text(
                      'Offered Items: $itemNames',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
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
              const SizedBox(height: AppDimensions.marginM),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        () =>
                            _respondToRequest(request, RequestStatus.declined),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: AppDimensions.marginS),
                  ElevatedButton(
                    onPressed:
                        () =>
                            _respondToRequest(request, RequestStatus.accepted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
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
