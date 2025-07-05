import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCondition { excellent, good, fair, poor }

enum ItemCategory {
  fruits,
  vegetables,
  grains,
  dairy,
  meat,
  canned,
  beverages,
  snacks,
  spices,
  other,
}

enum ItemStatus { available, pending, completed, expired }

class FoodItem {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final ItemCategory category;
  final ItemCondition condition;
  final int quantity;
  final String unit; // e.g., 'pieces', 'kg', 'liters'
  final DateTime? expiryDate;
  final List<String> imageUrls;
  final String reasonForOffering;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? location; // lat, lng, address
  final bool isForDonation;
  final bool isForBarter;
  final List<String> tags;
  final double? estimatedValue;

  const FoodItem({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.condition,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    this.imageUrls = const [],
    required this.reasonForOffering,
    this.status = ItemStatus.available,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.isForDonation = true,
    this.isForBarter = true,
    this.tags = const [],
    this.estimatedValue,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: ItemCategory.values.firstWhere(
        (cat) => cat.name == data['category'],
        orElse: () => ItemCategory.other,
      ),
      condition: ItemCondition.values.firstWhere(
        (cond) => cond.name == data['condition'],
        orElse: () => ItemCondition.good,
      ),
      quantity: data['quantity'] ?? 1,
      unit: data['unit'] ?? 'pieces',
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      reasonForOffering: data['reasonForOffering'] ?? '',
      status: ItemStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ItemStatus.available,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'],
      isForDonation: data['isForDonation'] ?? true,
      isForBarter: data['isForBarter'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      estimatedValue: data['estimatedValue']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'category': category.name,
      'condition': condition.name,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'imageUrls': imageUrls,
      'reasonForOffering': reasonForOffering,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'isForDonation': isForDonation,
      'isForBarter': isForBarter,
      'tags': tags,
      'estimatedValue': estimatedValue,
    };
  }

  FoodItem copyWith({
    String? name,
    String? description,
    ItemCategory? category,
    ItemCondition? condition,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    List<String>? imageUrls,
    String? reasonForOffering,
    ItemStatus? status,
    DateTime? updatedAt,
    Map<String, dynamic>? location,
    bool? isForDonation,
    bool? isForBarter,
    List<String>? tags,
    double? estimatedValue,
  }) {
    return FoodItem(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrls: imageUrls ?? this.imageUrls,
      reasonForOffering: reasonForOffering ?? this.reasonForOffering,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      location: location ?? this.location,
      isForDonation: isForDonation ?? this.isForDonation,
      isForBarter: isForBarter ?? this.isForBarter,
      tags: tags ?? this.tags,
      estimatedValue: estimatedValue ?? this.estimatedValue,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isNearExpiry {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate!.difference(now).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  String get categoryDisplayName {
    switch (category) {
      case ItemCategory.fruits:
        return 'Fruits';
      case ItemCategory.vegetables:
        return 'Vegetables';
      case ItemCategory.grains:
        return 'Grains';
      case ItemCategory.dairy:
        return 'Dairy';
      case ItemCategory.meat:
        return 'Meat';
      case ItemCategory.canned:
        return 'Canned';
      case ItemCategory.beverages:
        return 'Beverages';
      case ItemCategory.snacks:
        return 'Snacks';
      case ItemCategory.spices:
        return 'Spices';
      case ItemCategory.other:
        return 'Other';
    }
  }

  String get conditionDisplayName {
    switch (condition) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }
}
