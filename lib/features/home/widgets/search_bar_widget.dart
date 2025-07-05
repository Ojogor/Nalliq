import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final String? hintText;

  const SearchBarWidget({super.key, required this.onSearch, this.hintText});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2D2D30)
                : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : AppColors.grey)
                .withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearch,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search for food items...',
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.grey,
            size: AppDimensions.iconM,
          ),
          suffixIcon:
              _controller.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.grey,
                      size: AppDimensions.iconM,
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onSearch('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
        ),
      ),
    );
  }
}
