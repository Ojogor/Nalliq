import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../core/models/food_item_model.dart';

class ItemProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  List<FoodItem> _userItems = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;

  List<FoodItem> get userItems => _userItems;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;

  Future<void> loadUserItems(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final query =
          await _firestore
              .collection('items')
              .where('ownerId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      _userItems =
          query.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createItem({
    required String ownerId,
    required String name,
    required String description,
    required ItemCategory category,
    required ItemCondition condition,
    required int quantity,
    required String unit,
    DateTime? expiryDate,
    required String reasonForOffering,
    List<File>? images,
    bool isForDonation = true,
    bool isForBarter = true,
    List<String> tags = const [],
  }) async {
    try {
      _isCreating = true;
      _error = null;
      notifyListeners();

      // Upload images first
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        imageUrls = await _uploadImages(images, ownerId);
      }

      final itemId = _uuid.v4();
      final now = DateTime.now();

      final item = FoodItem(
        id: itemId,
        ownerId: ownerId,
        name: name,
        description: description,
        category: category,
        condition: condition,
        quantity: quantity,
        unit: unit,
        expiryDate: expiryDate,
        imageUrls: imageUrls,
        reasonForOffering: reasonForOffering,
        createdAt: now,
        updatedAt: now,
        isForDonation: isForDonation,
        isForBarter: isForBarter,
        tags: tags,
      );

      await _firestore.collection('items').doc(itemId).set(item.toFirestore());

      _userItems.insert(0, item);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<List<String>> _uploadImages(List<File> images, String ownerId) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final fileName = '${_uuid.v4()}.jpg';
      final path = 'items/$ownerId/$fileName';

      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<bool> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection('items').doc(itemId).update(updates);

      // Update local list
      final index = _userItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final doc = await _firestore.collection('items').doc(itemId).get();
        if (doc.exists) {
          _userItems[index] = FoodItem.fromFirestore(doc);
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('items').doc(itemId).delete();

      _userItems.removeWhere((item) => item.id == itemId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FoodItem?> getItemById(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (doc.exists) {
        return FoodItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
