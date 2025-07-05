import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/user_store_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<HomeProvider>(
          context,
          listen: false,
        ).loadHomeData(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);

    if (authProvider.user == null) {
      // This can be a loading spinner or a message,
      // while the app is checking the auth state.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Food Share'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.pushNamed('search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.pushNamed('cart'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => homeProvider.loadHomeData(authProvider.user!.uid),
          child:
              homeProvider.isLoading &&
                      homeProvider.communityStores.isEmpty &&
                      homeProvider.friendStores.isEmpty &&
                      homeProvider.foodBankStores.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildHomeContent(homeProvider),
        ),
      ),
    );
  }

  Widget _buildHomeContent(HomeProvider homeProvider) {
    if (homeProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              homeProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                homeProvider.refreshData(authProvider.user!.uid);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SectionHeader(title: 'Community Stores'),
        _buildStoreList(homeProvider.communityStores),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Friends Stores'),
        _buildStoreList(homeProvider.friendStores),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Food Bank Stores'),
        _buildStoreList(homeProvider.foodBankStores),
      ],
    );
  }

  Widget _buildStoreList(List<UserStore> stores) {
    if (stores.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No stores found in this category yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return UserStoreCard(
            store: store,
            onTap: () {
              // Navigate to store profile screen
              context.push('/store/${store.user.id}');
            },
          );
        },
      ),
    );
  }
}
