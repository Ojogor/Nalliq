import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType { barter, donation }

enum RequestStatus {
  pending,
  accepted,
  declined,
  barterConfirmed, // New status for when users agree and confirm the barter
  awaitingProof, // New status when users need to upload completion proof
  completed,
  cancelled,
}

class ExchangeRequest {
  final String id;
  final String requesterId;
  final String ownerId;
  final List<String> requestedItemIds;
  final List<String> offeredItemIds; // Empty for donation requests
  final RequestType type;
  final RequestStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;
  final String? meetingLocation;
  final DateTime? scheduledMeetingTime;
  final List<String> chatMessages;
  final Map<String, dynamic>? metadata;
  final List<String>? requesterProofImages; // Proof images from requester
  final List<String>? ownerProofImages; // Proof images from owner
  final DateTime? barterConfirmedAt; // When barter was confirmed
  final DateTime? proofSubmittedAt; // When proof was submitted

  const ExchangeRequest({
    required this.id,
    required this.requesterId,
    required this.ownerId,
    required this.requestedItemIds,
    this.offeredItemIds = const [],
    required this.type,
    this.status = RequestStatus.pending,
    this.message,
    required this.createdAt,
    this.respondedAt,
    this.completedAt,
    this.meetingLocation,
    this.scheduledMeetingTime,
    this.chatMessages = const [],
    this.metadata,
    this.requesterProofImages,
    this.ownerProofImages,
    this.barterConfirmedAt,
    this.proofSubmittedAt,
  });

  factory ExchangeRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExchangeRequest(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      requestedItemIds: List<String>.from(data['requestedItemIds'] ?? []),
      offeredItemIds: List<String>.from(data['offeredItemIds'] ?? []),
      type: RequestType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => RequestType.donation,
      ),
      status: RequestStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      message: data['message'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      respondedAt:
          data['respondedAt'] != null
              ? (data['respondedAt'] as Timestamp).toDate()
              : null,
      completedAt:
          data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
      meetingLocation: data['meetingLocation'],
      scheduledMeetingTime:
          data['scheduledMeetingTime'] != null
              ? (data['scheduledMeetingTime'] as Timestamp).toDate()
              : null,
      chatMessages: List<String>.from(data['chatMessages'] ?? []),
      metadata: data['metadata'],
      requesterProofImages:
          data['requesterProofImages'] != null
              ? List<String>.from(data['requesterProofImages'])
              : null,
      ownerProofImages:
          data['ownerProofImages'] != null
              ? List<String>.from(data['ownerProofImages'])
              : null,
      barterConfirmedAt:
          data['barterConfirmedAt'] != null
              ? (data['barterConfirmedAt'] as Timestamp).toDate()
              : null,
      proofSubmittedAt:
          data['proofSubmittedAt'] != null
              ? (data['proofSubmittedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'ownerId': ownerId,
      'requestedItemIds': requestedItemIds,
      'offeredItemIds': offeredItemIds,
      'type': type.name,
      'status': status.name,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'meetingLocation': meetingLocation,
      'scheduledMeetingTime':
          scheduledMeetingTime != null
              ? Timestamp.fromDate(scheduledMeetingTime!)
              : null,
      'chatMessages': chatMessages,
      'metadata': metadata,
      'requesterProofImages': requesterProofImages,
      'ownerProofImages': ownerProofImages,
      'barterConfirmedAt':
          barterConfirmedAt != null
              ? Timestamp.fromDate(barterConfirmedAt!)
              : null,
      'proofSubmittedAt':
          proofSubmittedAt != null
              ? Timestamp.fromDate(proofSubmittedAt!)
              : null,
    };
  }

  ExchangeRequest copyWith({
    RequestStatus? status,
    DateTime? respondedAt,
    DateTime? completedAt,
    String? meetingLocation,
    DateTime? scheduledMeetingTime,
    List<String>? chatMessages,
    Map<String, dynamic>? metadata,
    List<String>? requesterProofImages,
    List<String>? ownerProofImages,
    DateTime? barterConfirmedAt,
    DateTime? proofSubmittedAt,
  }) {
    return ExchangeRequest(
      id: id,
      requesterId: requesterId,
      ownerId: ownerId,
      requestedItemIds: requestedItemIds,
      offeredItemIds: offeredItemIds,
      type: type,
      status: status ?? this.status,
      message: message,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      scheduledMeetingTime: scheduledMeetingTime ?? this.scheduledMeetingTime,
      chatMessages: chatMessages ?? this.chatMessages,
      metadata: metadata ?? this.metadata,
      requesterProofImages: requesterProofImages ?? this.requesterProofImages,
      ownerProofImages: ownerProofImages ?? this.ownerProofImages,
      barterConfirmedAt: barterConfirmedAt ?? this.barterConfirmedAt,
      proofSubmittedAt: proofSubmittedAt ?? this.proofSubmittedAt,
    );
  }

  bool get isDonation => type == RequestType.donation;
  bool get isBarter => type == RequestType.barter;
  bool get isPending => status == RequestStatus.pending;
  bool get isAccepted => status == RequestStatus.accepted;
  bool get isCompleted => status == RequestStatus.completed;
  bool get isDeclined => status == RequestStatus.declined;
  bool get isCancelled => status == RequestStatus.cancelled;
  bool get isBarterConfirmed => status == RequestStatus.barterConfirmed;
  bool get isAwaitingProof => status == RequestStatus.awaitingProof;

  // Helper methods for proof status
  bool get hasRequesterProof => requesterProofImages?.isNotEmpty ?? false;
  bool get hasOwnerProof => ownerProofImages?.isNotEmpty ?? false;
  bool get hasBothProofs => hasRequesterProof && hasOwnerProof;
}
