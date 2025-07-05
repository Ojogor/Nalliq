import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/exchange_request_model.dart';
import '../../../core/models/food_item_model.dart';
import '../../auth/providers/auth_provider.dart';

class BarterDetailScreen extends StatefulWidget {
  final String requestId;

  const BarterDetailScreen({super.key, required this.requestId});

  @override
  State<BarterDetailScreen> createState() => _BarterDetailScreenState();
}

class _BarterDetailScreenState extends State<BarterDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _meetingLocationController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  ExchangeRequest? _request;
  List<FoodItem> _requestedItems = [];
  List<FoodItem> _offeredItems = [];
  final Map<String, String> _userDisplayNames = {};
  bool _isLoading = true;
  String? _error;
  DateTime? _selectedMeetingTime;
  List<File> _proofImages = [];

  @override
  void initState() {
    super.initState();
    _loadBarterDetails();
  }

  Future<void> _loadBarterDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load the exchange request
      final requestDoc =
          await _firestore
              .collection('exchange_requests')
              .doc(widget.requestId)
              .get();

      if (!requestDoc.exists) {
        setState(() {
          _error = 'Request not found';
          _isLoading = false;
        });
        return;
      }

      _request = ExchangeRequest.fromFirestore(requestDoc);

      // Load requested items
      if (_request!.requestedItemIds.isNotEmpty) {
        final requestedItemsQuery =
            await _firestore
                .collection('items')
                .where(
                  FieldPath.documentId,
                  whereIn: _request!.requestedItemIds,
                )
                .get();
        _requestedItems =
            requestedItemsQuery.docs
                .map((doc) => FoodItem.fromFirestore(doc))
                .toList();
      }

      // Load offered items (for barter)
      if (_request!.offeredItemIds.isNotEmpty) {
        final offeredItemsQuery =
            await _firestore
                .collection('items')
                .where(FieldPath.documentId, whereIn: _request!.offeredItemIds)
                .get();
        _offeredItems =
            offeredItemsQuery.docs
                .map((doc) => FoodItem.fromFirestore(doc))
                .toList();
      }

      // Load user display names
      await _loadUserDisplayName(_request!.requesterId);
      await _loadUserDisplayName(_request!.ownerId);

      // Pre-fill meeting location if available
      if (_request!.meetingLocation != null) {
        _meetingLocationController.text = _request!.meetingLocation!;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserDisplayName(String userId) async {
    if (_userDisplayNames.containsKey(userId)) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _userDisplayNames[userId] =
            userData['displayName'] ?? userData['email'] ?? 'Unknown User';
      } else {
        _userDisplayNames[userId] = 'Unknown User';
      }
    } catch (e) {
      _userDisplayNames[userId] = 'Unknown User';
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final message =
          '${_userDisplayNames[authProvider.user!.uid] ?? "You"}: ${_messageController.text.trim()}';

      final updatedMessages = List<String>.from(_request!.chatMessages)
        ..add(message);

      await _firestore
          .collection('exchange_requests')
          .doc(widget.requestId)
          .update({'chatMessages': updatedMessages});

      _messageController.clear();
      await _loadBarterDetails(); // Refresh to show new message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmBarter() async {
    if (_meetingLocationController.text.trim().isEmpty ||
        _selectedMeetingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set meeting location and time'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      await _firestore
          .collection('exchange_requests')
          .doc(widget.requestId)
          .update({
            'status': RequestStatus.barterConfirmed.name,
            'barterConfirmedAt': Timestamp.now(),
            'meetingLocation': _meetingLocationController.text.trim(),
            'scheduledMeetingTime': Timestamp.fromDate(_selectedMeetingTime!),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Barter confirmed! You can now proceed with the exchange.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      await _loadBarterDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming barter: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickProofImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _proofImages = images.map((xfile) => File(xfile.path)).toList();
      });
    }
  }

  Future<void> _submitProof() async {
    if (_proofImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select proof images'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final isOwner = authProvider.user!.uid == _request!.ownerId;

      // In a real app, you would upload images to Firebase Storage
      // For now, we'll just store placeholder URLs
      final imageUrls =
          _proofImages
              .map(
                (file) =>
                    'proof_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
              )
              .toList();

      Map<String, dynamic> updateData = {'proofSubmittedAt': Timestamp.now()};

      if (isOwner) {
        updateData['ownerProofImages'] = imageUrls;
      } else {
        updateData['requesterProofImages'] = imageUrls;
      }

      // Check if both users have submitted proof
      final currentRequest = _request!;
      final hasRequesterProof =
          !isOwner
              ? true
              : (currentRequest.requesterProofImages?.isNotEmpty ?? false);
      final hasOwnerProof =
          isOwner
              ? true
              : (currentRequest.ownerProofImages?.isNotEmpty ?? false);

      if (hasRequesterProof && hasOwnerProof) {
        updateData['status'] = RequestStatus.completed.name;
        updateData['completedAt'] = Timestamp.now();
      } else {
        updateData['status'] = RequestStatus.awaitingProof.name;
      }

      await _firestore
          .collection('exchange_requests')
          .doc(widget.requestId)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasRequesterProof && hasOwnerProof
                ? 'Barter completed successfully!'
                : 'Proof submitted! Waiting for other party.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() {
        _proofImages.clear();
      });

      await _loadBarterDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting proof: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Request not found'),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_request!.isBarter ? "Barter" : "Donation"} Details'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: AppDimensions.marginM),
            _buildItemsSection(),
            const SizedBox(height: AppDimensions.marginM),
            _buildChatSection(),
            const SizedBox(height: AppDimensions.marginM),
            if (_request!.isAccepted && !_request!.isBarterConfirmed)
              _buildConfirmationSection(),
            if (_request!.isBarterConfirmed && !_request!.isCompleted)
              _buildProofSection(),
            if (_request!.isCompleted) _buildCompletedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_request!.status) {
      case RequestStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Pending Response';
        statusIcon = Icons.hourglass_empty;
        break;
      case RequestStatus.accepted:
        statusColor = AppColors.info;
        statusText = 'Accepted - Arrange Details';
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.barterConfirmed:
        statusColor = AppColors.primaryGreen;
        statusText = 'Barter Confirmed - Proceed with Exchange';
        statusIcon = Icons.handshake;
        break;
      case RequestStatus.awaitingProof:
        statusColor = AppColors.warning;
        statusText = 'Awaiting Completion Proof';
        statusIcon = Icons.camera_alt;
        break;
      case RequestStatus.completed:
        statusColor = AppColors.success;
        statusText = 'Completed Successfully';
        statusIcon = Icons.done_all;
        break;
      case RequestStatus.declined:
        statusColor = AppColors.error;
        statusText = 'Declined';
        statusIcon = Icons.cancel;
        break;
      case RequestStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: AppDimensions.marginM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_request!.scheduledMeetingTime != null)
                    Text(
                      'Meeting: ${_request!.scheduledMeetingTime!.toString().split('.').first}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_request!.meetingLocation != null)
                    Text(
                      'Location: ${_request!.meetingLocation}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Requested Items
            Text(
              'Requested Items:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginS),
            ..._requestedItems.map((item) => _buildItemTile(item)),

            if (_offeredItems.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.marginM),
              Text(
                'Offered Items (in exchange):',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.marginS),
              ..._offeredItems.map((item) => _buildItemTile(item)),
            ],

            // Participants
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Participants:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginS),
            Text(
              'Requester: ${_userDisplayNames[_request!.requesterId] ?? "Unknown"}',
            ),
            Text('Owner: ${_userDisplayNames[_request!.ownerId] ?? "Unknown"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(FoodItem item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
        child: Icon(Icons.food_bank, color: AppColors.primaryGreen),
      ),
      title: Text(item.name),
      subtitle: Text(item.description),
      trailing: Text(
        '${item.quantity} ${item.unit}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildChatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Chat messages
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  _request!.chatMessages.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.builder(
                        itemCount: _request!.chatMessages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(_request!.chatMessages[index]),
                          );
                        },
                      ),
            ),

            // Message input
            const SizedBox(height: AppDimensions.marginM),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: AppDimensions.marginS),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Barter Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Meeting location
            TextField(
              controller: _meetingLocationController,
              decoration: const InputDecoration(
                labelText: 'Meeting Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Meeting time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                _selectedMeetingTime == null
                    ? 'Select Meeting Time'
                    : 'Meeting: ${_selectedMeetingTime.toString().split('.').first}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedMeetingTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),

            const SizedBox(height: AppDimensions.marginM),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBarter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Confirm Barter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    final authProvider = context.read<AuthProvider>();
    final isOwner = authProvider.user!.uid == _request!.ownerId;
    final hasSubmittedProof =
        isOwner
            ? (_request!.ownerProofImages?.isNotEmpty ?? false)
            : (_request!.requesterProofImages?.isNotEmpty ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Completion Proof',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),

            if (hasSubmittedProof) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: AppDimensions.marginS),
                    const Text('You have submitted your proof'),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Please upload photos showing the completed exchange as proof.',
              ),
              const SizedBox(height: AppDimensions.marginM),

              // Image picker
              if (_proofImages.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children:
                      _proofImages
                          .map(
                            (image) => Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(image, fit: BoxFit.cover),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: AppDimensions.marginM),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickProofImages,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _proofImages.isEmpty
                            ? 'Select Photos'
                            : 'Change Photos',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.marginS),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _proofImages.isEmpty ? null : _submitProof,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Submit Proof'),
                    ),
                  ),
                ],
              ),
            ],

            // Show other party's proof status
            const SizedBox(height: AppDimensions.marginM),
            const Divider(),
            const SizedBox(height: AppDimensions.marginS),

            Row(
              children: [
                Icon(
                  (_request!.requesterProofImages?.isNotEmpty ?? false)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                      (_request!.requesterProofImages?.isNotEmpty ?? false)
                          ? AppColors.success
                          : Colors.grey,
                ),
                const SizedBox(width: AppDimensions.marginS),
                Text('${_userDisplayNames[_request!.requesterId]} proof'),
              ],
            ),
            const SizedBox(height: AppDimensions.marginS),
            Row(
              children: [
                Icon(
                  (_request!.ownerProofImages?.isNotEmpty ?? false)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                      (_request!.ownerProofImages?.isNotEmpty ?? false)
                          ? AppColors.success
                          : Colors.grey,
                ),
                const SizedBox(width: AppDimensions.marginS),
                Text('${_userDisplayNames[_request!.ownerId]} proof'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedSection() {
    return Card(
      color: AppColors.success.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            Icon(Icons.celebration, size: 48, color: AppColors.success),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Barter Completed Successfully!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.marginS),
            Text(
              'Both parties have confirmed completion. Thank you for using Nalliq!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_request!.completedAt != null) ...[
              const SizedBox(height: AppDimensions.marginS),
              Text(
                'Completed on: ${_request!.completedAt.toString().split('.').first}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _meetingLocationController.dispose();
    super.dispose();
  }
}
