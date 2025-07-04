import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../screens/enhanced_add_item_screen.dart';
import 'barcode_scanner_widget.dart';

class ProductFormWidget extends StatefulWidget {
  final ProductDraft productDraft;
  final Function(ProductDraft) onProductUpdated;
  final VoidCallback onScanBarcode;
  final VoidCallback onRetakePhotos;
  final VoidCallback? onRemoveProduct;

  const ProductFormWidget({
    super.key,
    required this.productDraft,
    required this.onProductUpdated,
    required this.onScanBarcode,
    required this.onRetakePhotos,
    this.onRemoveProduct,
  });

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _reasonController;
  late TextEditingController _barcodeController;

  @override
  void initState() {
    super.initState();
    print(
      '🏁 ProductFormWidget initialized for product: ${widget.productDraft.name}',
    );
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.productDraft.name);
    _descriptionController = TextEditingController(
      text: widget.productDraft.description,
    );
    _quantityController = TextEditingController(
      text: widget.productDraft.quantity.toString(),
    );
    _unitController = TextEditingController(text: widget.productDraft.unit);
    _reasonController = TextEditingController(
      text: widget.productDraft.reasonForSharing,
    );
    _barcodeController = TextEditingController(
      text: widget.productDraft.barcode,
    );
  }

  @override
  void didUpdateWidget(ProductFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controllers when product draft changes (e.g., after autofill)
    if (oldWidget.productDraft != widget.productDraft) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _nameController.text = widget.productDraft.name;
    _descriptionController.text = widget.productDraft.description;
    _quantityController.text = widget.productDraft.quantity.toString();
    _unitController.text = widget.productDraft.unit;
    _reasonController.text = widget.productDraft.reasonForSharing;
    _barcodeController.text = widget.productDraft.barcode;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photos preview
            _buildPhotosPreview(),

            const SizedBox(height: AppDimensions.marginL),

            // Barcode section
            _buildBarcodeSection(),

            const SizedBox(height: AppDimensions.marginL),

            // Basic information
            _buildBasicInfoSection(),

            const SizedBox(height: AppDimensions.marginL),

            // Product details
            _buildDetailsSection(),

            const SizedBox(height: AppDimensions.marginL),

            // Sharing options
            _buildSharingOptionsSection(),

            // Add some bottom padding for the bottom action bar
            const SizedBox(height: 100), // Space for bottom action bar
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product Photos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.productDraft.photos.length}/4',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        widget.productDraft.photos.length >= 4
                            ? AppColors.success
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginS),
            if (widget.productDraft.photos.isEmpty)
              _buildAddPhotosButton()
            else
              _buildPhotosGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotosButton() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: InkWell(
        onTap: _showPhotoSourceDialog,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: AppColors.grey),
            const SizedBox(height: AppDimensions.marginS),
            Text(
              'Add Photos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'From camera or gallery',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 1.0,
              mainAxisSpacing: AppDimensions.marginS,
            ),
            itemCount: widget.productDraft.photos.length,
            itemBuilder: (context, index) {
              final photo = widget.productDraft.photos[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusS,
                      ),
                      border: Border.all(
                        color: AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusS,
                      ),
                      child: Image.file(photo, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.productDraft.photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.productDraft.photos.length} photo(s) added',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              TextButton.icon(
                onPressed: _showPhotoSourceDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add More'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBarcodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: AppColors.primaryGreen),
                const SizedBox(width: AppDimensions.marginS),
                Text(
                  'Barcode & Product Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Barcode input with camera button
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode (Optional)',
                      hintText: 'Scan or enter manually',
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    readOnly: true,
                    onChanged: (value) {
                      _updateDraft(barcode: value);
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.marginS),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BarcodeScannerWidget(
                              onBarcodeScanned: (code) {
                                _barcodeController.text = code;
                                _updateDraft(barcode: code);
                                // Optionally trigger auto-fill after scanning
                                widget.onScanBarcode();
                              },
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan Barcode/QR Code',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.marginM),

            // Auto-fill button (full width below barcode)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onScanBarcode,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Auto-fill Product Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (widget.productDraft.brand.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.marginS),
              Text(
                'Brand: ${widget.productDraft.brand}',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (widget.productDraft.categories.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.marginS),
              Text(
                'Categories: ${widget.productDraft.categories}',
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Item Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g., Fresh Bananas, Canned Tomatoes',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
              onChanged: (value) {
                _updateDraft(name: value);
              },
            ),

            const SizedBox(height: AppDimensions.marginM),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Additional details about the item...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                _updateDraft(description: value);
              },
            ),

            const SizedBox(height: AppDimensions.marginM),

            // Category Dropdown
            DropdownButtonFormField<ItemCategory>(
              value: widget.productDraft.category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items:
                  ItemCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryDisplayName(category)),
                    );
                  }).toList(),
              onChanged: (category) {
                _updateDraft(category: category);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Quantity and Unit Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter quantity';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final quantity = double.tryParse(value) ?? 1.0;
                      _updateDraft(quantity: quantity);
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.marginM),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      hintText: 'kg, pieces, cans, etc.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter unit';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _updateDraft(unit: value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.marginM),

            // Condition Dropdown
            DropdownButtonFormField<ItemCondition>(
              value: widget.productDraft.condition,
              decoration: const InputDecoration(
                labelText: 'Condition *',
                border: OutlineInputBorder(),
              ),
              items:
                  ItemCondition.values.map((condition) {
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(_getConditionDisplayName(condition)),
                    );
                  }).toList(),
              onChanged: (condition) {
                _updateDraft(condition: condition);
              },
            ),

            const SizedBox(height: AppDimensions.marginM),

            // Expiry Date (Optional)
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      widget.productDraft.expiryDate ??
                      DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  _updateDraft(expiryDate: date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.productDraft.expiryDate != null
                          ? 'Expires: ${widget.productDraft.expiryDate!.day}/${widget.productDraft.expiryDate!.month}/${widget.productDraft.expiryDate!.year}'
                          : 'Set Expiry Date (Optional)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sharing Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),

            // Reason for sharing
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Sharing',
                hintText: 'e.g., Have extra, Moving away, etc.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateDraft(reasonForSharing: value);
              },
            ),

            const SizedBox(height: AppDimensions.marginM),

            // Sharing type switches
            SwitchListTile(
              title: const Text('Available for Donation'),
              subtitle: const Text('Give away for free'),
              value: widget.productDraft.isForDonation,
              onChanged: (value) {
                _updateDraft(isForDonation: value);
              },
              activeColor: AppColors.primaryGreen,
            ),

            SwitchListTile(
              title: const Text('Available for Barter'),
              subtitle: const Text('Exchange for other items'),
              value: widget.productDraft.isForBarter,
              onChanged: (value) {
                _updateDraft(isForBarter: value);
              },
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  void _updateDraft({
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
  }) {
    print(
      '📝 Updating product draft: name=$name, category=$category, isValid=${widget.productDraft.isValid}',
    );
    final updatedDraft = widget.productDraft.copyWith(
      name: name,
      description: description,
      category: category,
      condition: condition,
      quantity: quantity,
      unit: unit,
      expiryDate: expiryDate,
      isForDonation: isForDonation,
      isForBarter: isForBarter,
      reasonForSharing: reasonForSharing,
      barcode: barcode,
    );
    print(
      '✅ Updated product draft - isValid: ${updatedDraft.isValid}, photos: ${updatedDraft.photos.length}',
    );
    widget.onProductUpdated(updatedDraft);
  }

  String _getCategoryDisplayName(ItemCategory category) {
    switch (category) {
      case ItemCategory.fruits:
        return 'Fruits';
      case ItemCategory.vegetables:
        return 'Vegetables';
      case ItemCategory.dairy:
        return 'Dairy Products';
      case ItemCategory.meat:
        return 'Meat & Fish';
      case ItemCategory.grains:
        return 'Grains & Cereals';
      case ItemCategory.snacks:
        return 'Snacks & Treats';
      case ItemCategory.beverages:
        return 'Beverages';
      case ItemCategory.canned:
        return 'Canned Goods';
      case ItemCategory.spices:
        return 'Spices & Herbs';
      case ItemCategory.other:
        return 'Other';
    }
  }

  String _getConditionDisplayName(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _reasonController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Photos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to add photos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoSourceOption(
                        icon: Icons.camera_alt,
                        title: 'Camera',
                        subtitle: 'Take new photos',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromCamera();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPhotoSourceOption(
                        icon: Icons.photo_library,
                        title: 'Gallery',
                        subtitle: 'Choose from gallery',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromGallery();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildPhotoSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        _addPhotoToProduct(File(image.path));
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing camera: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        for (XFile image in images) {
          _addPhotoToProduct(File(image.path));
        }
      }
    } catch (e) {
      print('Error picking images from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing gallery: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _addPhotoToProduct(File photo) {
    final updatedPhotos = List<File>.from(widget.productDraft.photos)
      ..add(photo);

    final updatedDraft = widget.productDraft.copyWith(photos: updatedPhotos);
    widget.onProductUpdated(updatedDraft);

    setState(() {});
  }

  void _removePhoto(int index) {
    final updatedPhotos = List<File>.from(widget.productDraft.photos)
      ..removeAt(index);

    final updatedDraft = widget.productDraft.copyWith(photos: updatedPhotos);
    widget.onProductUpdated(updatedDraft);

    setState(() {});
  }
}
