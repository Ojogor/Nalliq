import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Debug method to check current user authentication status
  static void checkAuthStatus() {
    final user = _auth.currentUser;
    print('=== AUTH DEBUG ===');
    print('Current user: ${user?.uid}');
    print('Email: ${user?.email}');
    print('Display name: ${user?.displayName}');
    print('Is authenticated: ${user != null}');
    print('==================');
  }

  /// Debug method to check if there are any items in Firestore
  static Future<void> checkItemsInFirestore() async {
    try {
      print('=== FIRESTORE ITEMS DEBUG ===');

      final snapshot = await _firestore.collection('items').get();
      print('Total items in collection: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('No items found in Firestore!');
        print('Creating sample items...');
        await createSampleItems();
      } else {
        print('Items found:');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print(
            '- ${data['name']} (Owner: ${data['ownerId']}, Status: ${data['status']})',
          );
        }
      }

      print('============================');
    } catch (e) {
      print('Error checking items: $e');
    }
  }

  /// Debug method to check if there are any users in Firestore
  static Future<void> checkUsersInFirestore() async {
    try {
      print('=== FIRESTORE USERS DEBUG ===');

      final snapshot = await _firestore.collection('users').get();
      print('Total users in collection: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        print('Users found:');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print(
            '- ${data['displayName']} (${data['email']}, Role: ${data['role']})',
          );
        }
      }

      print('=============================');
    } catch (e) {
      print('Error checking users: $e');
    }
  }

  /// Create sample items for testing
  static Future<void> createSampleItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user to create sample items');
        return;
      }

      // First, ensure user exists in Firestore
      await ensureUserExists(user);

      final sampleItems = [
        {
          'id': 'sample-1',
          'ownerId': user.uid,
          'name': 'Fresh Apples',
          'description': 'Organic red apples from my garden',
          'category': 'fruits',
          'condition': 'excellent',
          'quantity': 5,
          'unit': 'kg',
          'status': 'available',
          'isForDonation': true,
          'isForBarter': true,
          'reasonForOffering': 'Too many apples from harvest',
          'imageUrls': [],
          'tags': ['organic', 'fresh'],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'sample-2',
          'ownerId': user.uid,
          'name': 'Homemade Bread',
          'description': 'Fresh baked whole wheat bread',
          'category': 'grains',
          'condition': 'excellent',
          'quantity': 2,
          'unit': 'loaves',
          'status': 'available',
          'isForDonation': true,
          'isForBarter': false,
          'reasonForOffering': 'Made extra for sharing',
          'imageUrls': [],
          'tags': ['homemade', 'whole-wheat'],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'sample-3',
          'ownerId': user.uid,
          'name': 'Fresh Vegetables',
          'description': 'Mixed vegetables from local farm',
          'category': 'vegetables',
          'condition': 'good',
          'quantity': 3,
          'unit': 'kg',
          'status': 'available',
          'isForDonation': false,
          'isForBarter': true,
          'reasonForOffering': 'Looking to trade for fruits',
          'imageUrls': [],
          'tags': ['local', 'farm-fresh'],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];
      for (var item in sampleItems) {
        await _firestore
            .collection('items')
            .doc(item['id'] as String)
            .set(item);
        print('Created sample item: ${item['name']}');
      }

      print('Sample items created successfully!');
    } catch (e) {
      print('Error creating sample items: $e');
    }
  }

  /// Ensure the current user exists in Firestore users collection
  static Future<void> ensureUserExists(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'User',
          'photoUrl': user.photoURL,
          'role': 'user',
          'trustScore': 5.0,
          'trustLevel': 'bronze',
          'friendIds': <String>[],
          'location': {'address': 'Unknown', 'latitude': 0.0, 'longitude': 0.0},
          'preferences': {
            'notificationsEnabled': true,
            'shareLocation': false,
            'autoAcceptFromFriends': false,
          },
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };

        await _firestore.collection('users').doc(user.uid).set(userData);
        print('Created user document for: ${user.email}');
      } else {
        print('User document exists for: ${user.email}');
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
    }
  }

  /// Create a sample food bank user for testing
  static Future<void> createSampleFoodBank() async {
    try {
      const foodBankId = 'sample-food-bank-1';

      final foodBankData = {
        'uid': foodBankId,
        'email': 'foodbank@example.com',
        'displayName': 'Community Food Bank',
        'photoUrl': null,
        'role': 'foodBank',
        'trustScore': 10.0,
        'trustLevel': 'gold',
        'friendIds': <String>[],
        'location': {
          'address': 'Downtown Community Center',
          'latitude': 43.6532,
          'longitude': -79.3832,
        },
        'preferences': {
          'notificationsEnabled': true,
          'shareLocation': true,
          'autoAcceptFromFriends': false,
        },
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('users').doc(foodBankId).set(foodBankData);

      // Create some food bank items
      final foodBankItems = [
        {
          'id': 'foodbank-item-1',
          'ownerId': foodBankId,
          'name': 'Canned Soup',
          'description': 'Nutritious vegetable soup',
          'category': 'canned',
          'condition': 'excellent',
          'quantity': 20,
          'unit': 'cans',
          'status': 'available',
          'isForDonation': true,
          'isForBarter': false,
          'reasonForOffering': 'Community support',
          'imageUrls': [],
          'tags': ['nutritious', 'canned'],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];
      for (var item in foodBankItems) {
        await _firestore
            .collection('items')
            .doc(item['id'] as String)
            .set(item);
      }

      print('Created sample food bank and items!');
    } catch (e) {
      print('Error creating sample food bank: $e');
    }
  }

  /// Run comprehensive debug check
  static Future<void> runFullDebugCheck() async {
    print('\n🔍 Starting comprehensive debug check...\n');

    checkAuthStatus();
    await checkUsersInFirestore();
    await checkItemsInFirestore();

    print('\n✅ Debug check completed!\n');
  }
}
