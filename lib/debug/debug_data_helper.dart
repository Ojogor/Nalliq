import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_model.dart';
import '../core/models/food_item_model.dart';

class DebugDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> debugDataLoad() async {
    print('🔍 === DEBUG DATA LOAD ===');

    try {
      // Check users collection
      print('👥 Checking users collection...');
      final usersSnapshot = await _firestore.collection('users').get();
      print('   Total users: ${usersSnapshot.docs.length}');
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        print(
          '   User: ${data['displayName']} (${doc.id}) - Role: ${data['role']}',
        );

        // Highlight the specific user we know has items
        if (doc.id == 'QBy4SvUGjKcydW3eu4cypbYfuZ92') {
          print('   ⭐ This is the user with the "tedt" item!');
        }
      }

      // Check items collection
      print('\n📦 Checking items collection...');
      final itemsSnapshot = await _firestore.collection('items').get();
      print('   Total items: ${itemsSnapshot.docs.length}');
      for (final doc in itemsSnapshot.docs) {
        final data = doc.data();
        print(
          '   Item: ${data['name']} - Owner: ${data['ownerId']} - Status: ${data['status']} - Fields: ${data.keys.toList()}',
        );
      } // Check different role queries
      print('\n🔍 Testing different role queries...');

      // Test 'individual'
      final individualUsers =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'individual')
              .get();
      print('   Users with role "individual": ${individualUsers.docs.length}');

      // Test 'user'
      final userRoleUsers =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'user')
              .get();
      print('   Users with role "user": ${userRoleUsers.docs.length}');

      // Test 'foodBank'
      final foodBankUsers =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'foodBank')
              .get();
      print('   Users with role "foodBank": ${foodBankUsers.docs.length}');

      // Show items without status filter
      print('\n📦 Checking items without status filter...');
      final allItems = await _firestore.collection('items').get();
      print('   Total items (no filter): ${allItems.docs.length}');

      final availableItems =
          await _firestore
              .collection('items')
              .where('status', isEqualTo: 'available')
              .get();
      print('   Items with status "available": ${availableItems.docs.length}');

      print('\n✅ Debug data load completed');
    } catch (e) {
      print('❌ Debug data load error: $e');
    }
  }
}
