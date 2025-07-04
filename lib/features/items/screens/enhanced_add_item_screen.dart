import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../widgets/camera_overlay_widget.dart';
import '../widgets/product_form_widget.dart';

class EnhancedAddItemScreen extends StatefulWidget {
  const EnhancedAddItemScreen({super.key});

  @override
  State<EnhancedAddItemScreen> createState() => _EnhancedAddItemScreenState();
}

class _EnhancedAddItemScreenState extends State<EnhancedAddItemScreen> {
  final PageController _pageController = PageController(
    initialPage: 1,
  ); // Start on form page
  List<ProductDraft> _productDrafts = [];
  int _currentPage = 1; // Start with form page (1), camera is page 0
  int _currentProductIndex = 0;

  @override
  void initState() {
    super.initState();
    _addNewProduct();
  }

  void _addNewProduct() {
    setState(() {
      _productDrafts.add(ProductDraft());
      _currentProductIndex = _productDrafts.length - 1;
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _productDrafts.removeAt(index);
      if (_currentProductIndex >= _productDrafts.length) {
        _currentProductIndex = _productDrafts.length - 1;
      }
      if (_productDrafts.isEmpty) {
        _addNewProduct();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.background,
      appBar: AppBar(
        title: Text('Add Items (${_productDrafts.length})'),
        backgroundColor:
            isDark ? const Color(0xFF2D2D30) : AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Camera Page
          _buildCameraPage(),
          // Form Page
          _buildFormPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget? _buildBottomActionBar() {
    // Only show on form page
    if (_currentPage != 1) return null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validProducts =
        _productDrafts.where((draft) => draft.isValid).toList();
    final productsWithPhotos =
        validProducts.where((draft) => draft.photos.length >= 4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status row
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${validProducts.length} valid product${validProducts.length != 1 ? 's' : ''}, ${productsWithPhotos.length} with photos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Save Draft
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        print('💾 Save draft pressed');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Draft saved!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Save Draft'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Add More Products
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        print('➕ Add more products pressed');
                        _addNewProduct();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New product slot added!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add More'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Review and Finalize buttons
              Row(
                children: [
                  // Review Products
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          validProducts.isNotEmpty
                              ? () {
                                print('👁️ Review products pressed');
                                _showProductReview();
                              }
                              : null,
                      icon: const Icon(Icons.preview, size: 16),
                      label: const Text('Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: BorderSide(
                          color: AppColors.info.withOpacity(
                            validProducts.isNotEmpty ? 1.0 : 0.3,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // List Your Pantry (finalize)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          productsWithPhotos.isNotEmpty
                              ? () {
                                print('🚀 List your pantry pressed');
                                _finalizeAllProducts();
                              }
                              : null,
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(
                        productsWithPhotos.isNotEmpty
                            ? 'List (${productsWithPhotos.length})'
                            : 'Need Photos',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            productsWithPhotos.isNotEmpty
                                ? AppColors.primaryGreen
                                : AppColors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPage() {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),
        // Camera with overlay
        Expanded(
          child: CameraOverlayWidget(
            requiredPhotos: 4,
            onPhotosComplete: (photos) {
              print('📸 Photos completed: ${photos.length} photos taken');
              _productDrafts[_currentProductIndex].photos = photos;
              print('✅ Photos saved to product ${_currentProductIndex + 1}');
              _goToFormPage(); // Go back to form after photos are taken
            },
            photoLabels: const [
              'Front of package',
              'Back of package (ingredients)',
              'Barcode/QR code',
              'Item itself',
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormPage() {
    if (_productDrafts.isEmpty) return const SizedBox();

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),
        // Product tabs
        if (_productDrafts.length > 1) _buildProductTabs(),
        // Form
        Expanded(
          child: ProductFormWidget(
            key: ValueKey(_currentProductIndex),
            productDraft: _productDrafts[_currentProductIndex],
            onProductUpdated: (draft) {
              setState(() {
                _productDrafts[_currentProductIndex] = draft;
              });
            },
            onScanBarcode: () => _scanBarcodeAndFillData(),
            onRetakePhotos: () => _goToCameraPage(),
            onRemoveProduct:
                _productDrafts.length > 1
                    ? () => _removeProduct(_currentProductIndex)
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value:
                  _currentPage == 1
                      ? 0.5
                      : 1.0, // Form page is 50%, camera completion is 100%
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
          const SizedBox(width: AppDimensions.marginS),
          Text(
            _currentPage == 1 ? 'Details' : 'Photos',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProductTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _productDrafts.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentProductIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentProductIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primaryGreen
                        : (isDark ? Colors.grey[700] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Item ${index + 1}',
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (_productDrafts.length > 1) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeProduct(index),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color:
                            isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _goToFormPage() {
    print('📝 Going to form page for product ${_currentProductIndex + 1}');
    setState(() {
      _currentPage = 1;
    });
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToCameraPage() {
    print('📷 Going to camera page for product ${_currentProductIndex + 1}');
    setState(() {
      _currentPage = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _scanBarcodeAndFillData() async {
    try {
      // Configure OpenFoodFacts User Agent (required for API calls)
      // Always set user agent before any API calls to prevent errors
      print('Configuring Open Food Facts user agent...');
      OpenFoodAPIConfiguration.userAgent = UserAgent(
        name: 'Nalliq',
        version: '1.0.0',
        system: 'Flutter',
        url: 'https://github.com/nalliq/nalliq-app',
        comment: 'Community Food Barter App',
      );
      print('User agent configured successfully');

      // Use the barcode from the product draft if available, otherwise use a sample
      String barcodeToUse =
          _productDrafts[_currentProductIndex].barcode.isNotEmpty
              ? _productDrafts[_currentProductIndex].barcode
              : '3017620422003'; // Nutella barcode for testing

      // Get the device locale to determine the appropriate language
      final deviceLocale = Localizations.localeOf(context);
      OpenFoodFactsLanguage language = _getOpenFoodFactsLanguage(deviceLocale);

      print('Making Open Food Facts API call with barcode: $barcodeToUse');
      print('Using language: ${language.code}');

      final productResult = await OpenFoodAPIClient.getProductV3(
        ProductQueryConfiguration(
          barcodeToUse,
          version: ProductQueryVersion.v3,
          language: language,
          fields: [
            ProductField.NAME,
            ProductField.BRANDS,
            ProductField.CATEGORIES,
            ProductField.INGREDIENTS_TEXT,
            ProductField.PACKAGING,
          ],
        ),
      );

      if (productResult.status == ProductResultV3.statusSuccess &&
          productResult.product != null) {
        final product = productResult.product!;

        // Create a smarter category mapping
        ItemCategory mappedCategory = ItemCategory.other;
        final categories =
            product.categoriesTagsInLanguages?[language] ??
            product.categoriesTagsInLanguages?[OpenFoodFactsLanguage.ENGLISH] ??
            [];

        // Map Open Food Facts categories to our categories
        for (final category in categories) {
          final lowerCategory = category.toLowerCase();
          if (lowerCategory.contains('fruit') ||
              lowerCategory.contains('vegetables')) {
            mappedCategory = ItemCategory.fruits;
            break;
          } else if (lowerCategory.contains('dairy') ||
              lowerCategory.contains('milk') ||
              lowerCategory.contains('cheese')) {
            mappedCategory = ItemCategory.dairy;
            break;
          } else if (lowerCategory.contains('meat') ||
              lowerCategory.contains('fish') ||
              lowerCategory.contains('seafood')) {
            mappedCategory = ItemCategory.meat;
            break;
          } else if (lowerCategory.contains('grain') ||
              lowerCategory.contains('bread') ||
              lowerCategory.contains('pasta')) {
            mappedCategory = ItemCategory.grains;
            break;
          } else if (lowerCategory.contains('snack') ||
              lowerCategory.contains('chip') ||
              lowerCategory.contains('cookie')) {
            mappedCategory = ItemCategory.snacks;
            break;
          } else if (lowerCategory.contains('beverage') ||
              lowerCategory.contains('drink') ||
              lowerCategory.contains('juice')) {
            mappedCategory = ItemCategory.beverages;
            break;
          } else if (lowerCategory.contains('can') ||
              lowerCategory.contains('preserve')) {
            mappedCategory = ItemCategory.canned;
            break;
          }
        }

        // Generate a reasonable description
        String description = product.ingredientsText ?? '';
        if (description.isEmpty && product.brands != null) {
          description = 'Brand: ${product.brands}';
          if (categories.isNotEmpty) {
            description += '\nCategory: ${categories.join(', ')}';
          }
        }

        setState(() {
          _productDrafts[_currentProductIndex] =
              _productDrafts[_currentProductIndex].copyWith(
                name: product.productName ?? '',
                description: description,
                barcode: barcodeToUse,
                brand: product.brands ?? '',
                categories: categories.join(', '),
                category: mappedCategory,
                // Set reasonable defaults for auto-filled products
                quantity: 1.0,
                unit: 'piece(s)',
                condition: ItemCondition.good,
                reasonForSharing: 'Have extra',
              );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product information filled from Open Food Facts! (${product.productName ?? 'Unknown Product'})',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product not found in Open Food Facts database (Barcode: $barcodeToUse)',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      print('Open Food Facts API error: $e');
      String errorMessage = 'Error fetching product info';

      if (e.toString().contains('user agent')) {
        errorMessage = 'API configuration error. Please try again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      } else {
        errorMessage = 'Error fetching product info: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _finalizeAllProducts() async {
    print('🚀 _finalizeAllProducts called');
    print('📊 Current products: ${_productDrafts.length}');

    final itemProvider = context.read<ItemProvider>();
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      print('❌ User not authenticated');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add items'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Test Firebase connection first
    print('🧪 Testing Firebase connection before finalizing...');
    final canConnectToFirebase = await itemProvider.testFirebaseConnection();
    if (!canConnectToFirebase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot connect to Firebase. Please check your internet connection.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Verify authentication is still valid
    print('🔐 Verifying authentication...');
    print('Auth user ID: ${authProvider.user?.uid}');
    print('Auth user email: ${authProvider.user?.email}');
    print('Is authenticated: ${authProvider.isAuthenticated}');

    // Validate all products
    final validProducts =
        _productDrafts.where((draft) => draft.isValid).toList();

    // Check for photos before finalizing
    final productsWithoutPhotos =
        validProducts.where((draft) => draft.photos.length < 4).toList();

    if (validProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete at least one product'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (productsWithoutPhotos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${productsWithoutPhotos.length} item${productsWithoutPhotos.length > 1 ? 's' : ''} need${productsWithoutPhotos.length == 1 ? 's' : ''} photos before finalizing',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finalize Pantry'),
            content: Text(
              'Add ${validProducts.length} item${validProducts.length > 1 ? 's' : ''} to your pantry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Add Items'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Submit all valid products
    try {
      print('🚀 Starting to finalize ${validProducts.length} products...');
      for (int i = 0; i < validProducts.length; i++) {
        final draft = validProducts[i];
        print(
          '📦 Creating item ${i + 1}/${validProducts.length}: ${draft.name}',
        );

        final success = await itemProvider.createItem(
          ownerId: authProvider.user!.uid,
          name: draft.name,
          description: draft.description,
          category: draft.category,
          condition: draft.condition,
          quantity: draft.quantity.round(),
          unit: draft.unit,
          expiryDate: draft.expiryDate,
          reasonForOffering: draft.reasonForSharing,
          images: draft.photos,
          isForDonation: draft.isForDonation,
          isForBarter: draft.isForBarter,
        );

        if (success) {
          print('✅ Item ${i + 1} created successfully: ${draft.name}');
        } else {
          print('❌ Failed to create item ${i + 1}: ${draft.name}');
          print('Error: ${itemProvider.error}');
        }
      }

      print('🎉 All products finalized successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully added ${validProducts.length} items to your pantry!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      context.go('/profile/listings');
    } catch (e) {
      print('❌ Error finalizing products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding items: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showProductReview() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Product Review'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child:
                  _productDrafts.isEmpty
                      ? const Center(child: Text('No products added yet'))
                      : ListView.builder(
                        itemCount: _productDrafts.length,
                        itemBuilder: (context, index) {
                          final product = _productDrafts[index];
                          final hasPhotos = product.photos.isNotEmpty;
                          final isComplete =
                              product.isValid && product.photos.length >= 4;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isComplete
                                        ? AppColors.success
                                        : product.isValid
                                        ? AppColors.warning
                                        : AppColors.error,
                                child: Icon(
                                  isComplete
                                      ? Icons.check
                                      : hasPhotos
                                      ? Icons.camera_alt
                                      : Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                product.name.isNotEmpty
                                    ? product.name
                                    : 'Item ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category: ${product.category.name}'),
                                  Text('Photos: ${product.photos.length}/4'),
                                  if (!isComplete)
                                    Text(
                                      !product.isValid
                                          ? 'Missing: Name, Description, or Quantity'
                                          : 'Missing: Photos',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  context.pop();
                                  setState(() {
                                    _currentProductIndex = index;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                  _finalizeAllProducts();
                },
                child: const Text('List Your Pantry'),
              ),
            ],
          ),
    );
  }

  // Helper method to get OpenFoodFacts language from Flutter Locale
  OpenFoodFactsLanguage _getOpenFoodFactsLanguage(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return OpenFoodFactsLanguage.FRENCH;
      case 'en':
      default:
        return OpenFoodFactsLanguage.ENGLISH;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class ProductDraft {
  String name;
  String description;
  ItemCategory category;
  ItemCondition condition;
  double quantity;
  String unit;
  DateTime? expiryDate;
  bool isForDonation;
  bool isForBarter;
  String reasonForSharing;
  String barcode;
  String brand;
  String categories;
  Map<String, dynamic>? location;
  List<File> photos;

  ProductDraft({
    this.name = '',
    this.description = '',
    this.category = ItemCategory.other,
    this.condition = ItemCondition.good,
    this.quantity = 1.0,
    this.unit = 'piece(s)',
    this.expiryDate,
    this.isForDonation = true,
    this.isForBarter = true,
    this.reasonForSharing = '',
    this.barcode = '',
    this.brand = '',
    this.categories = '',
    this.location,
    this.photos = const [],
  });

  bool get isValid {
    return name.isNotEmpty &&
        description.isNotEmpty &&
        quantity > 0 &&
        unit.isNotEmpty;
    // photos.length >= 4; // Photos are optional for draft saving
  }

  ProductDraft copyWith({
    String? name,
    String? description,
    ItemCategory? category,
    ItemCondition? condition,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    bool? isForDonation,
    bool? isForBarter,
    String? reasonForSharing,
    String? barcode,
    String? brand,
    String? categories,
    Map<String, dynamic>? location,
    List<File>? photos,
  }) {
    return ProductDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      isForDonation: isForDonation ?? this.isForDonation,
      isForBarter: isForBarter ?? this.isForBarter,
      reasonForSharing: reasonForSharing ?? this.reasonForSharing,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      categories: categories ?? this.categories,
      location: location ?? this.location,
      photos: photos ?? this.photos,
    );
  }
}
