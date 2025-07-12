import 'package:ichizen/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateInputField extends StatelessWidget {
  final String labelText;
  final IconData icon;
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final String? hintText; // Optional hint text for when no date is chosen

  const CustomDateInputField({
    super.key,
    required this.labelText,
    required this.icon,
    required this.selectedDate,
    required this.onTap,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
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
        baseStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.textDark,
        ), // Consistent text style
        child: Text(
          selectedDate == null
              ? hintText ?? 'Select ${labelText.toLowerCase()}'
              : DateFormat('yyyy-MM-dd').format(selectedDate!),
          style: TextStyle(
            color: selectedDate == null
                ? AppColors.placeholder
                : AppColors.textDark, // Consistent placeholder/text color
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
