import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time cleanup function to remove placeholder URLs from user profiles
/// Call this once to clean up existing bad data in your database
class ProfileUrlCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Removes all placeholder URLs from user profiles in Firestore
  static Future<void> cleanupPlaceholderUrls() async {
    try {
      print('Starting profile URL cleanup...');

      // Query all users with the placeholder URL
      final query =
          await _firestore
              .collection('users')
              .where(
                'photoUrl',
                isEqualTo: 'https://example.com/uploaded-photo.jpg',
              )
              .get();

      print('Found ${query.docs.length} users with placeholder URLs');

      // Update each user to remove the placeholder URL
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'photoUrl': null});
      }

      // Commit the batch update
      await batch.commit();

      print('Successfully cleaned up ${query.docs.length} user profiles');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  /// Alternative method to clean up ANY URLs containing "example.com"
  static Future<void> cleanupAllExampleUrls() async {
    try {
      print('Starting comprehensive URL cleanup...');

      // Get all users (since Firestore doesn't support contains queries on strings)
      final query = await _firestore.collection('users').get();

      final batch = _firestore.batch();
      int cleanedCount = 0;

      for (final doc in query.docs) {
        final data = doc.data();
        final photoUrl = data['photoUrl'] as String?;

        if (photoUrl != null && photoUrl.contains('example.com')) {
          batch.update(doc.reference, {'photoUrl': null});
          cleanedCount++;
        }
      }

      if (cleanedCount > 0) {
        await batch.commit();
        print('Successfully cleaned up $cleanedCount user profiles');
      } else {
        print('No profiles needed cleanup');
      }
    } catch (e) {
      print('Error during comprehensive cleanup: $e');
    }
  }
}
