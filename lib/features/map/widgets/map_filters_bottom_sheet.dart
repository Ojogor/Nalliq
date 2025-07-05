import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/food_item_model.dart';

enum FilterType { distance, userType, itemCategory, rating }

enum UserType { all, community, friends, foodBanks }

class MapFilter {
  final FilterType type;
  final String name;
  final dynamic value;
  final bool isActive;

  MapFilter({
    required this.type,
    required this.name,
    required this.value,
    this.isActive = false,
  });

  MapFilter copyWith({
    FilterType? type,
    String? name,
    dynamic value,
    bool? isActive,
  }) {
    return MapFilter(
      type: type ?? this.type,
      name: name ?? this.name,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
    );
  }
}

class MapFiltersBottomSheet extends StatefulWidget {
  final List<MapFilter> currentFilters;
  final Function(List<MapFilter>) onFiltersChanged;

  const MapFiltersBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<MapFiltersBottomSheet> createState() => _MapFiltersBottomSheetState();
}

class _MapFiltersBottomSheetState extends State<MapFiltersBottomSheet> {
  late List<MapFilter> _filters;
  double _maxDistance = 10.0; // km
  UserType _selectedUserType = UserType.all;
  ItemCategory? _selectedCategory;
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _filters = List.from(widget.currentFilters);
    _initializeFromCurrentFilters();
  }

  void _initializeFromCurrentFilters() {
    for (final filter in _filters) {
      switch (filter.type) {
        case FilterType.distance:
          if (filter.isActive) _maxDistance = filter.value;
          break;
        case FilterType.userType:
          if (filter.isActive) _selectedUserType = filter.value;
          break;
        case FilterType.itemCategory:
          if (filter.isActive) _selectedCategory = filter.value;
          break;
        case FilterType.rating:
          if (filter.isActive) _minRating = filter.value;
          break;
      }
    }
  }

  void _updateFilters() {
    _filters = [
      MapFilter(
        type: FilterType.distance,
        name: 'Within ${_maxDistance.toInt()} km',
        value: _maxDistance,
        isActive: _maxDistance < 50.0,
      ),
      MapFilter(
        type: FilterType.userType,
        name: _getUserTypeName(_selectedUserType),
        value: _selectedUserType,
        isActive: _selectedUserType != UserType.all,
      ),
      MapFilter(
        type: FilterType.itemCategory,
        name:
            _selectedCategory != null
                ? _getCategoryName(_selectedCategory!)
                : 'All Categories',
        value: _selectedCategory,
        isActive: _selectedCategory != null,
      ),
      MapFilter(
        type: FilterType.rating,
        name: 'Rating ${_minRating.toStringAsFixed(1)}+',
        value: _minRating,
        isActive: _minRating > 0.0,
      ),
    ];
  }

  String _getUserTypeName(UserType type) {
    switch (type) {
      case UserType.all:
        return 'All Users';
      case UserType.community:
        return 'Community';
      case UserType.friends:
        return 'Friends Only';
      case UserType.foodBanks:
        return 'Food Banks';
    }
  }

  String _getCategoryName(ItemCategory category) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D30) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Map Filters',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _maxDistance = 50.0;
                      _selectedUserType = UserType.all;
                      _selectedCategory = null;
                      _minRating = 0.0;
                    });
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance filter
                  _buildSectionTitle('Distance Range'),
                  const SizedBox(height: 12),
                  _buildDistanceFilter(),

                  const SizedBox(height: 24),

                  // User type filter
                  _buildSectionTitle('User Type'),
                  const SizedBox(height: 12),
                  _buildUserTypeFilter(),

                  const SizedBox(height: 24),

                  // Category filter
                  _buildSectionTitle('Item Categories'),
                  const SizedBox(height: 12),
                  _buildCategoryFilter(),

                  const SizedBox(height: 24),

                  // Rating filter
                  _buildSectionTitle('Minimum Rating'),
                  const SizedBox(height: 12),
                  _buildRatingFilter(),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D3D3D) : Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _updateFilters();
                  widget.onFiltersChanged(_filters);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      children: [
        Slider(
          value: _maxDistance,
          min: 1.0,
          max: 50.0,
          divisions: 49,
          activeColor: AppColors.primaryGreen,
          label: '${_maxDistance.toInt()} km',
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${_maxDistance.toInt()} km',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            Text('50+ km', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          UserType.values.map((type) {
            final isSelected = _selectedUserType == type;
            return FilterChip(
              selected: isSelected,
              label: Text(_getUserTypeName(type)),
              onSelected: (selected) {
                setState(() {
                  _selectedUserType = type;
                });
              },
              selectedColor: AppColors.primaryGreen.withOpacity(0.2),
              checkmarkColor: AppColors.primaryGreen,
              side: BorderSide(
                color: isSelected ? AppColors.primaryGreen : Colors.grey,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      children: [
        // All categories option
        FilterChip(
          selected: _selectedCategory == null,
          label: const Text('All Categories'),
          onSelected: (selected) {
            setState(() {
              _selectedCategory = null;
            });
          },
          selectedColor: AppColors.primaryGreen.withOpacity(0.2),
          checkmarkColor: AppColors.primaryGreen,
          side: BorderSide(
            color:
                _selectedCategory == null
                    ? AppColors.primaryGreen
                    : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        // Individual categories
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ItemCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  selected: isSelected,
                  label: Text(_getCategoryName(category)),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryGreen,
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryGreen : Colors.grey,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      children: [
        Slider(
          value: _minRating,
          min: 0.0,
          max: 5.0,
          divisions: 50,
          activeColor: AppColors.primaryGreen,
          label: _minRating.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _minRating = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.0', style: Theme.of(context).textTheme.bodySmall),
            Row(
              children: [
                Text(
                  _minRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, color: Colors.amber, size: 16),
              ],
            ),
            Text('5.0', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
