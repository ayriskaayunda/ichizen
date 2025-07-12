// lib/screens/profile/edit_profile_screen.dart
import 'dart:convert'; // For base64 encoding
import 'dart:io'; // For File operations

import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for image picking

// Hapus import untuk CustomInputField dan PrimaryButton karena kita menggunakan widget standar
// import '../../widgets/custom_input_field.dart';
// import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser; // Changed type to User

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  // Menghapus controller untuk Email dan Nomor Telepon
  // late TextEditingController _emailController;
  // late TextEditingController _phoneController;

  File? _pickedImage; // State for newly picked profile photo file
  String? _profilePhotoBase64; // Base64 for the newly picked photo to upload
  String? _initialProfilePhotoUrl; // To store the original URL from currentUser

  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    // Initialize controller with current user's name
    _nameController = TextEditingController(
      text: widget.currentUser.name, // Use .name property
    );

    // Menghapus inisialisasi controller Email dan Telepon
    // _emailController = TextEditingController(text: widget.currentUser.email);
    // _phoneController = TextEditingController(text: widget.currentUser.noTelp ?? '');

    // Store the initial profile photo URL from the current user
    _initialProfilePhotoUrl = widget.currentUser.profile_photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Menghapus dispose controller Email dan Telepon
    // _emailController.dispose();
    // _phoneController.dispose();
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      // Convert image to base64 for upload
      List<int> imageBytes = await _pickedImage!.readAsBytes();
      _profilePhotoBase64 = base64Encode(imageBytes);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String newName = _nameController.text.trim();

      bool profileDetailsChanged = false;
      bool profilePhotoChanged = false;

      // 1. Check if name has changed and update
      final bool nameChanged = newName != widget.currentUser.name;

      if (nameChanged) {
        try {
          final ApiResponse<User> response = await _apiService.updateProfile(
            name: newName,
          );

          if (response.statusCode == 200 && response.data != null) {
            profileDetailsChanged = true;
          } else {
            String errorMessage = response.message;
            if (response.errors != null) {
              response.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile details: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if detail update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating details: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Check if a new profile photo has been selected and upload
      if (_pickedImage != null && _profilePhotoBase64 != null) {
        try {
          final ApiResponse<User> photoResponse = await _apiService
              .updateProfilePhoto(profilePhoto: _profilePhotoBase64!);

          if (photoResponse.statusCode == 200 && photoResponse.data != null) {
            profilePhotoChanged = true;
            // IMPORTANT: Update the initialProfilePhotoUrl with the new URL from the API response
            if (photoResponse.data!.profile_photo != null) {
              _initialProfilePhotoUrl = photoResponse.data!.profile_photo;
            }
            // Clear picked image and base64 as it's now saved and reflected by URL
            _pickedImage = null;
            _profilePhotoBase64 = null;
          } else {
            String errorMessage = photoResponse.message;
            if (photoResponse.errors != null) {
              photoResponse.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile photo: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if photo update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating photo: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      if (profileDetailsChanged || profilePhotoChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true); // Pop with true to signal refresh
      } else {
        // If no changes were made to either name/gender or photo
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No changes to save.")));
      }

      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construct full URL for existing profile photo
    ImageProvider<Object>? currentImageProvider;
    if (_pickedImage != null) {
      // If a new image is picked, use it
      currentImageProvider = FileImage(_pickedImage!);
    } else if (_initialProfilePhotoUrl != null &&
        _initialProfilePhotoUrl!.isNotEmpty) {
      // If no new image, but there's an initial URL, use NetworkImage
      // Check if the URL is already a full URL or a relative path
      final String fullImageUrl = _initialProfilePhotoUrl!.startsWith('http')
          ? _initialProfilePhotoUrl!
          : 'https://appabsensi.mobileprojp.com/public/' +
                _initialProfilePhotoUrl!; // Adjust base path as needed
      currentImageProvider = NetworkImage(fullImageUrl);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profil', // Mengubah teks judul
          style: TextStyle(
            color: Colors.white, // Warna foreground
            fontSize: 20, // Ukuran font
            fontWeight: FontWeight.bold, // Tebal
          ),
        ),
        backgroundColor: const Color(0xFF624F82), // Warna latar belakang AppBar
        foregroundColor: Colors.white, // Warna ikon/teks di AppBar
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        backgroundImage:
                            currentImageProvider, // Use the determined image provider
                        child: currentImageProvider == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.textLight,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text(
                        _pickedImage != null ||
                                (_initialProfilePhotoUrl != null &&
                                    _initialProfilePhotoUrl!.isNotEmpty)
                            ? 'Ganti Foto' // Mengubah teks
                            : 'Unggah Foto', // Mengubah teks
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ), // Space between image section and first input
              // Nama Lengkap
              const Text(
                'Nama Lengkap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama lengkap Anda',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30), // Mengurangi spasi setelah nama
              // Menghapus bagian Email dan Nomor Telepon
              // const Text(
              //   'Email',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 8),
              // TextFormField(
              //   controller: _emailController,
              //   keyboardType: TextInputType.emailAddress,
              //   readOnly: true,
              //   decoration: const InputDecoration(
              //     hintText: 'Masukkan alamat email Anda',
              //     border: OutlineInputBorder(),
              //     prefixIcon: Icon(Icons.email),
              //   ),
              // ),
              // const SizedBox(height: 20),
              // const Text(
              //   'Nomor Telepon',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 8),
              // TextFormField(
              //   controller: _phoneController,
              //   keyboardType: TextInputType.phone,
              //   readOnly: true,
              //   decoration: const InputDecoration(
              //     hintText: 'Masukkan nomor telepon Anda',
              //     border: OutlineInputBorder(),
              //     prefixIcon: Icon(Icons.phone),
              //   ),
              // ),
              // const SizedBox(height: 30),

              // Save Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF624F82,
                          ), // Warna latar belakang tombol
                          foregroundColor: Colors.white, // Warna teks tombol
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan', // Mengubah teks tombol
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
