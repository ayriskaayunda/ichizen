import 'package:ichizen/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText; // This remains the primary hint text for the field
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? toggleVisibility;

  // NEW: Optional properties for more flexibility
  final String? labelText; // For a floating label above the input
  final int? maxLines; // For multi-line text input
  final TextInputType?
  keyboardType; // For specifying keyboard type (e.g., multiline, email)
  final String? Function(String?)?
  customValidator; // For providing a specific validation function
  final Color? fillColor; // To override the default fill color
  final EdgeInsetsGeometry?
  contentPadding; // To override the default content padding
  final bool readOnly; // Re-added readOnly property

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText, // Existing required parameter
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.toggleVisibility,
    // Initialize new optional parameters
    this.labelText,
    this.maxLines = 1, // Default to single line
    this.keyboardType,
    this.customValidator, // Renamed to avoid clash with internal _defaultValidator
    this.fillColor,
    this.contentPadding,
    this.readOnly = false, // Default readOnly to false
  });

  // Auto-validator based on field type. This will be used if customValidator is not provided.
  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your ${hintText.toLowerCase()}';
    }

    if (hintText.toLowerCase().contains('email')) {
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    if (hintText.toLowerCase().contains('password')) {
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
    }

    if (hintText.toLowerCase().contains('username') ||
        hintText.toLowerCase().contains('name')) {
      if (value.length < 3) {
        return '$hintText must be at least 3 characters';
      }
    }

    return null; // valid
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines, // Apply maxLines
      keyboardType: keyboardType, // Apply keyboardType
      readOnly: readOnly, // Apply the readOnly property here
      validator:
          customValidator ??
          _defaultValidator, // Use custom validator if provided, else default
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText:
            labelText, // NEW: Use labelText if provided (for floating label)
        hintText:
            hintText, // EXISTING: Continues to be used as hintText (inner placeholder)
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        filled: true,
        fillColor:
            fillColor ??
            Colors.grey.shade100, // Use custom fill color or default
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
