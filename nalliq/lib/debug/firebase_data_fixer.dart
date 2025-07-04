import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fix user roles that are null or missing
  static Future<void> fixUserRoles() async {
    try {
      print('🔧 Starting user role fix...');

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      print('📊 Found ${usersSnapshot.docs.length} users to check');

      int fixedCount = 0;
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final currentRole = data['role'];

        print('👤 User ${doc.id}: role = $currentRole');

        // If role is null or missing, set it to 'individual' (community user)
        if (currentRole == null) {
          await doc.reference.update({
            'role':
                'individual', // Use 'individual' as default community user role
          });
          print('✅ Fixed user ${doc.id} - set role to "individual"');
          fixedCount++;
        }
      }

      print('🎉 Fixed $fixedCount users');

      // Also check if we have any items without status
      await _fixItemStatuses();
    } catch (e) {
      print('❌ Error fixing user roles: $e');
    }
  }

  /// Fix item statuses that are null or missing
  static Future<void> _fixItemStatuses() async {
    try {
      print('🔧 Checking item statuses...');

      // Get all items
      final itemsSnapshot = await _firestore.collection('items').get();
      print('📦 Found ${itemsSnapshot.docs.length} items to check');

      int fixedCount = 0;
      for (final doc in itemsSnapshot.docs) {
        final data = doc.data();
        final currentStatus = data['status'];

        if (currentStatus == null) {
          await doc.reference.update({
            'status': 'available', // Set default status
          });
          print('✅ Fixed item ${doc.id} - set status to "available"');
          fixedCount++;
        }
      }

      print('🎉 Fixed $fixedCount items');
    } catch (e) {
      print('❌ Error fixing item statuses: $e');
    }
  }
}
