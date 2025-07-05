import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../widgets/user_store_card.dart';

enum StoreListType { community, friends, foodBank }

enum StoreSortOption { distance, trustScore, items }

class StoreListScreen extends StatefulWidget {
  final StoreListType storeType;

  const StoreListScreen({super.key, required this.storeType});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  StoreSortOption _sortOption = StoreSortOption.distance;

  String _getTitle() {
    switch (widget.storeType) {
      case StoreListType.community:
        return 'Community Stores';
      case StoreListType.friends:
        return 'Friend Stores';
      case StoreListType.foodBank:
        return 'Food Bank Stores';
    }
  }

  List<UserStore> _getSortedStores(HomeProvider homeProvider) {
    List<UserStore> stores;
    switch (widget.storeType) {
      case StoreListType.community:
        stores = List.from(homeProvider.communityStores);
        break;
      case StoreListType.friends:
        stores = List.from(homeProvider.friendStores);
        break;
      case StoreListType.foodBank:
        stores = List.from(homeProvider.foodBankStores);
        break;
    }

    stores.sort((a, b) {
      switch (_sortOption) {
        case StoreSortOption.distance:
          return (a.distanceKm ?? double.maxFinite).compareTo(
            b.distanceKm ?? double.maxFinite,
          );
        case StoreSortOption.trustScore:
          return b.user.trustScore.compareTo(a.user.trustScore);
        case StoreSortOption.items:
          return b.totalItems.compareTo(a.totalItems);
      }
    });

    return stores;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Sort by Distance'),
              onTap: () {
                setState(() {
                  _sortOption = StoreSortOption.distance;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Sort by Trust Score'),
              onTap: () {
                setState(() {
                  _sortOption = StoreSortOption.trustScore;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Sort by Item Count'),
              onTap: () {
                setState(() {
                  _sortOption = StoreSortOption.items;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final stores = _getSortedStores(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showSortOptions,
            tooltip: 'Sort Stores',
          ),
        ],
      ),
      body: SafeArea(
        child:
            stores.isEmpty
                ? const Center(child: Text('No stores found in this category.'))
                : ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: UserStoreCard(
                        store: store,
                        onTap: () {
                          context.push('/home/store/${store.user.id}');
                        },
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
