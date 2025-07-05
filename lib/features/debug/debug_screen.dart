import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../debug/test_data_helper.dart';
import '../../debug/debug_data_helper.dart';
import '../../debug/add_sample_users.dart';
import '../../features/auth/providers/auth_provider.dart' as AppAuth;
import '../../features/home/providers/home_provider.dart';
import '../../features/items/providers/item_provider.dart';
import '../../features/location/providers/new_location_provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addToOutput(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
  }

  void _clearOutput() {
    setState(() {
      _debugOutput = '';
    });
  }

  Future<void> _runFullDebugCheck() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    _addToOutput('🔍 Starting comprehensive debug check...\n');

    // Check authentication
    final user = FirebaseAuth.instance.currentUser;
    _addToOutput('=== AUTH DEBUG ===');
    _addToOutput('Current user: ${user?.uid}');
    _addToOutput('Email: ${user?.email}');
    _addToOutput('Display name: ${user?.displayName}');
    _addToOutput('Is authenticated: ${user != null}');
    _addToOutput('==================\n'); // Check providers
    final authProvider = context.read<AppAuth.AuthProvider>();
    final homeProvider = context.read<HomeProvider>();
    final itemProvider = context.read<ItemProvider>();

    _addToOutput('=== PROVIDER DEBUG ===');
    _addToOutput(
      'AuthProvider isAuthenticated: ${authProvider.isAuthenticated}',
    );
    _addToOutput('AuthProvider user: ${authProvider.user?.uid}');
    _addToOutput('AuthProvider appUser: ${authProvider.appUser?.displayName}');
    _addToOutput('HomeProvider isLoading: ${homeProvider.isLoading}');
    _addToOutput('HomeProvider error: ${homeProvider.error}');
    _addToOutput(
      'HomeProvider foodBankItems: ${homeProvider.foodBankItems.length}',
    );
    _addToOutput(
      'HomeProvider friendsItems: ${homeProvider.friendsItems.length}',
    );
    _addToOutput(
      'HomeProvider communityItems: ${homeProvider.communityItems.length}',
    );
    _addToOutput('ItemProvider userItems: ${itemProvider.userItems.length}');
    _addToOutput('ItemProvider error: ${itemProvider.error}');
    _addToOutput('=====================\n');

    await TestDataHelper.checkUsersInFirestore();
    await TestDataHelper.checkItemsInFirestore();

    _addToOutput('\n✅ Debug check completed!');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createSampleData() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('Creating sample data...\n');

    try {
      await TestDataHelper.createSampleItems();
      await TestDataHelper.createSampleFoodBank();
      _addToOutput('✅ Sample data created successfully!');
    } catch (e) {
      _addToOutput('❌ Error creating sample data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshHomeData() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('Refreshing home data...\n');
    try {
      final authProvider = context.read<AppAuth.AuthProvider>();
      final homeProvider = context.read<HomeProvider>();

      if (authProvider.isAuthenticated && authProvider.user != null) {
        await homeProvider.loadHomeData(authProvider.user!.uid);
        _addToOutput('✅ Home data refreshed successfully!');
        _addToOutput('Food bank items: ${homeProvider.foodBankItems.length}');
        _addToOutput('Friends items: ${homeProvider.friendsItems.length}');
        _addToOutput('Community items: ${homeProvider.communityItems.length}');
      } else {
        _addToOutput('❌ User not authenticated');
      }
    } catch (e) {
      _addToOutput('❌ Error refreshing home data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserItems() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('Loading user items...\n');
    try {
      final authProvider = context.read<AppAuth.AuthProvider>();
      final itemProvider = context.read<ItemProvider>();

      if (authProvider.isAuthenticated && authProvider.user != null) {
        await itemProvider.loadUserItems(authProvider.user!.uid);
        _addToOutput('✅ User items loaded successfully!');
        _addToOutput('User items count: ${itemProvider.userItems.length}');

        for (var item in itemProvider.userItems) {
          _addToOutput('- ${item.name} (${item.status})');
        }
      } else {
        _addToOutput('❌ User not authenticated');
      }
    } catch (e) {
      _addToOutput('❌ Error loading user items: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _runDebugDataHelper() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    _addToOutput('🔍 Running Debug Data Helper...\n');

    try {
      await DebugDataHelper.debugDataLoad();
      _addToOutput('✅ Debug Data Helper executed successfully!');
    } catch (e) {
      _addToOutput('❌ Error running Debug Data Helper: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fixCurrentUserData() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('🔧 Fixing current user data...\n');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addToOutput('❌ No user is currently logged in');
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // Fix the current user's role
      _addToOutput('📝 Setting user role to "individual"...');
      await firestore.collection('users').doc(user.uid).update({
        'role': 'individual', // Set as community user
      });
      _addToOutput('✅ User role updated!');

      // Also check and fix any items without status
      _addToOutput('📦 Checking items...');
      final itemsQuery =
          await firestore
              .collection('items')
              .where('ownerId', isEqualTo: user.uid)
              .get();

      int itemsFixed = 0;
      for (final doc in itemsQuery.docs) {
        final data = doc.data();
        if (data['status'] == null) {
          await doc.reference.update({'status': 'available'});
          itemsFixed++;
        }
      }
      _addToOutput('✅ Fixed $itemsFixed items without status');

      // Refresh the home data after fixing
      _addToOutput('🔄 Refreshing home data...');
      final authProvider = context.read<AppAuth.AuthProvider>();
      final homeProvider = context.read<HomeProvider>();

      if (authProvider.isAuthenticated) {
        await homeProvider.loadHomeData(user.uid);
        _addToOutput('✅ Home data refreshed!');
        _addToOutput('📊 New counts:');
        _addToOutput(
          '   Community stores: ${homeProvider.communityStores.length}',
        );
        _addToOutput('   Friend stores: ${homeProvider.friendStores.length}');
        _addToOutput(
          '   Food bank stores: ${homeProvider.foodBankStores.length}',
        );
      }
    } catch (e) {
      _addToOutput('❌ Error fixing user data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addSampleUsers() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('🧪 Adding sample users for map testing...\n');
    try {
      await SampleUserHelper.addSampleUsers();
      _addToOutput('✅ Sample users added successfully!');
      _addToOutput('📍 Check the map to see multiple users now');
    } catch (e) {
      _addToOutput('❌ Error adding sample users: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _removeSampleUsers() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('🧹 Removing sample users...\n');
    try {
      await SampleUserHelper.removeSampleUsers();
      _addToOutput('✅ Sample users removed successfully!');
    } catch (e) {
      _addToOutput('❌ Error removing sample users: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testNearbyUsersStream() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('🧪 Testing nearby users stream...\n');
    try {
      // Get the LocationProvider to test the stream
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      final stream = locationProvider.nearbyUsersStream;

      _addToOutput('📡 Listening to stream for 5 seconds...');

      // Listen to the stream for a few seconds
      final subscription = stream.listen(
        (users) {
          _addToOutput('📦 Stream data received: ${users.length} users');
          for (final user in users) {
            _addToOutput('  👤 ${user.name} (${user.id})');
            _addToOutput('    📍 Location: ${user.location.address}');
            _addToOutput(
              '    🌐 Coordinates: ${user.location.latitude}, ${user.location.longitude}',
            );
            _addToOutput('    👁️ Visible: ${user.location.isVisible}');
          }
        },
        onError: (error) {
          _addToOutput('❌ Stream error: $error');
        },
      );

      // Cancel after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        subscription.cancel();
        _addToOutput('⏹️ Stream test completed');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      _addToOutput('❌ Error testing stream: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Debug Panel'),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Action buttons
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runFullDebugCheck,
                  child: const Text('Full Debug Check'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createSampleData,
                  child: const Text('Create Sample Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _refreshHomeData,
                  child: const Text('Refresh Home Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadUserItems,
                  child: const Text('Load User Items'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runDebugDataHelper,
                  child: const Text('Run Debug Data Helper'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fixCurrentUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fix User Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addSampleUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Sample Users'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _removeSampleUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Remove Sample Users'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fixCurrentUserData,
                  child: const Text('Fix Current User Data'),
                ),
                ElevatedButton(
                  onPressed: _clearOutput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('Clear Output'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addSampleUsers,
                  child: const Text('Add Sample Users'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _removeSampleUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('Remove Sample Users'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testNearbyUsersStream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Users Stream'),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingM),
              child: CircularProgressIndicator(),
            ),

          // Debug output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.marginM),
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugOutput.isEmpty
                      ? 'Tap any button above to start debugging...'
                      : _debugOutput,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
