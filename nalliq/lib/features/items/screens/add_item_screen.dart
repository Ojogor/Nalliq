import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../auth/widgets/auth_button.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _reasonController = TextEditingController();

  ItemCategory _selectedCategory = ItemCategory.other;
  ItemCondition _selectedCondition = ItemCondition.good;
  DateTime? _expiryDate;
  List<File> _selectedImages = [];
  bool _isForDonation = true;
  bool _isForBarter = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.addItem),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer2<ItemProvider, AuthProvider>(
        builder: (context, itemProvider, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image picker section
                  _buildImagePicker(),

                  const SizedBox(height: AppDimensions.marginL),

                  // Basic info
                  _buildBasicInfo(),

                  const SizedBox(height: AppDimensions.marginL),

                  // Details
                  _buildDetails(),

                  const SizedBox(height: AppDimensions.marginL),

                  // Options
                  _buildOptions(),

                  const SizedBox(height: AppDimensions.marginXL),

                  // Submit button
                  AuthButton(
                    text: 'Add Item',
                    isLoading: itemProvider.isCreating,
                    onPressed: () => _handleSubmit(itemProvider, authProvider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Text(
              AppStrings.photos,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: AppDimensions.marginS),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusS,
                          ),
                          child: Image.file(
                            _selectedImages[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: AppColors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.marginM),
          ],

          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: AppDimensions.marginM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppDimensions.marginM),

          AuthTextField(
            controller: _nameController,
            labelText: AppStrings.itemName,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter item name';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.marginM),

          AuthTextField(
            controller: _descriptionController,
            labelText: AppStrings.description,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter description';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Category dropdown
          DropdownButtonFormField<ItemCategory>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items:
                ItemCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplayName(category)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppDimensions.marginM),

          Row(
            children: [
              Expanded(
                child: AuthTextField(
                  controller: _quantityController,
                  labelText: AppStrings.quantity,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter quantity';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Enter valid quantity';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.marginM),
              Expanded(
                child: AuthTextField(
                  controller: _unitController,
                  labelText: 'Unit (e.g., kg, pieces)',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter unit';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Condition dropdown
          DropdownButtonFormField<ItemCondition>(
            value: _selectedCondition,
            decoration: const InputDecoration(labelText: 'Condition'),
            items:
                ItemCondition.values.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(_getConditionDisplayName(condition)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCondition = value;
                });
              }
            },
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Expiry date picker
          InkWell(
            onTap: _pickExpiryDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Expiry Date (Optional)',
              ),
              child: Text(
                _expiryDate != null
                    ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                    : 'Select expiry date',
                style: TextStyle(
                  color:
                      _expiryDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.marginM),

          AuthTextField(
            controller: _reasonController,
            labelText: AppStrings.reason,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter reason for offering';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability Options',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppDimensions.marginM),

          CheckboxListTile(
            title: const Text('Available for Donation'),
            subtitle: const Text('Allow others to request this item for free'),
            value: _isForDonation,
            onChanged: (value) {
              setState(() {
                _isForDonation = value ?? true;
              });
            },
            activeColor: AppColors.primaryGreen,
            contentPadding: EdgeInsets.zero,
          ),

          CheckboxListTile(
            title: const Text('Available for Barter'),
            subtitle: const Text('Allow others to offer items in exchange'),
            value: _isForBarter,
            onChanged: (value) {
              setState(() {
                _isForBarter = value ?? true;
              });
            },
            activeColor: AppColors.primaryOrange,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _handleSubmit(
    ItemProvider itemProvider,
    AuthProvider authProvider,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isForDonation && !_isForBarter) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one availability option'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (authProvider.user == null) return;

    final success = await itemProvider.createItem(
      ownerId: authProvider.user!.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      condition: _selectedCondition,
      quantity: int.parse(_quantityController.text.trim()),
      unit: _unitController.text.trim(),
      expiryDate: _expiryDate,
      reasonForOffering: _reasonController.text.trim(),
      images: _selectedImages.isNotEmpty ? _selectedImages : null,
      isForDonation: _isForDonation,
      isForBarter: _isForBarter,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(itemProvider.error ?? 'Failed to add item'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getCategoryDisplayName(ItemCategory category) {
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
}
