import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType { barter, donation }

enum RequestStatus { pending, accepted, declined, completed, cancelled }

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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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
    );
  }

  bool get isDonation => type == RequestType.donation;
  bool get isBarter => type == RequestType.barter;
  bool get isPending => status == RequestStatus.pending;
  bool get isAccepted => status == RequestStatus.accepted;
  bool get isCompleted => status == RequestStatus.completed;
  bool get isDeclined => status == RequestStatus.declined;
  bool get isCancelled => status == RequestStatus.cancelled;
}
