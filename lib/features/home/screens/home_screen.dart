import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/user_store_card.dart';
import '../widgets/section_header.dart';
import '../../../core/localization/app_localizations.dart';

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
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);

      if (authProvider.user != null) {
        homeProvider.loadHomeData(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);

    if (authProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.pushNamed('maps'),
            tooltip: AppLocalizations.of(context).communityMap,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('search'),
            tooltip: AppLocalizations.of(context).search,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.pushNamed('cart'),
            tooltip: AppLocalizations.of(context).cart,
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
                  : _buildHomeContent(homeProvider, context),
        ),
      ),
    );
  }

  Widget _buildHomeContent(HomeProvider homeProvider, BuildContext context) {
    if (homeProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).errorLoadingData,
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
              child: Text(AppLocalizations.of(context).tryAgain),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Community Stores Section
        SectionHeader(
          title: AppLocalizations.of(context).communityStores,
          onSeeAll: () => context.push('/home/stores/community'),
        ),
        const SizedBox(height: 12),
        _buildStoreList(homeProvider.communityStores, 'community'),
        const SizedBox(height: 32),

        // Friends Stores Section
        SectionHeader(
          title: AppLocalizations.of(context).friendsStores,
          onSeeAll: () => context.push('/home/stores/friends'),
        ),
        const SizedBox(height: 12),
        _buildStoreList(homeProvider.friendStores, 'friends'),
        const SizedBox(height: 32),

        // Food Bank Stores Section
        SectionHeader(
          title: AppLocalizations.of(context).foodBankStores,
          onSeeAll: () => context.push('/home/stores/foodBank'),
        ),
        const SizedBox(height: 12),
        _buildStoreList(homeProvider.foodBankStores, 'foodBank'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStoreList(List<UserStore> stores, String category) {
    if (stores.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 32,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).noStoresFound,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: UserStoreCard(
              store: store,
              onTap: () => context.push('/home/store/${store.user.id}'),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'community':
        return Icons.people;
      case 'friends':
        return Icons.group;
      case 'foodBank':
        return Icons.food_bank;
      default:
        return Icons.store;
    }
  }
}
