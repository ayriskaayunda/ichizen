import 'package:ichizen/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomDropdownInputField<T> extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double? menuMaxHeight; // NEW: Added menuMaxHeight
  final String? Function(T?)? validator; // NEW: Added validator

  const CustomDropdownInputField({
    super.key,
    required this.labelText,
    this.hintText,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.menuMaxHeight, // Initialize new parameter
    this.validator, // Initialize new parameter
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hintText ?? 'Select ${labelText.toLowerCase()}',
        style: const TextStyle(color: AppColors.placeholder),
      ),
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textDark,
      ), // Consistent text style
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: AppColors.textLight,
        ), // Consistent label style
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ), // Match CustomInputField's border radius
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.inputFill, // Consistent fill color
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ), // Consistent icon styling
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ), // Consistent padding
      ),
      menuMaxHeight: menuMaxHeight, // Apply menuMaxHeight here
      validator: validator, // Apply validator here
      isExpanded: true, // Keep this to prevent overflow
    );
  }
}
