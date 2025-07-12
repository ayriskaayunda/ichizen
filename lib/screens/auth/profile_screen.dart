// lib/screens/profile/profile_screen.dart
import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/screens/auth/edit_profile_screen.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Keep this import for DateFormat if you use it for displaying dates in UI

import '../../routes/app_routes.dart'; // Your AppRoutes
import '../../constants/app_text_styles.dart'; // Import your AppTextStyles

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const ProfileScreen({super.key, required this.refreshNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  User? _currentUser; // Holds the full user data (from API)
  bool _isLoading = false; // Add loading state

  bool _notificationEnabled = true; // State for the notification switch

  @override
  void initState() {
    super.initState();
    _loadUserData();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      print('ProfileScreen: Refresh signal received, refreshing profile...');
      _loadUserData(); // Re-fetch user data on refresh signal
      widget.refreshNotifier.value = false; // Reset the notifier
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });

    final ApiResponse<User> response = await _apiService.getProfile();

    setState(() {
      _isLoading = false; // Set loading to false
    });

    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _currentUser = response.data;
        // You might also want to load the notification preference from the user model
        // if you store it there:
        // _notificationEnabled = user?.notificationPreference ?? true;
      });
    } else {
      String errorMessage = response.message;
      // Perbaikan: Tambahkan null check sebelum mengulang response.errors
      if (response.errors != null) {
        response.errors!.forEach((key, value) {
          // Pastikan value adalah List sebelum melakukan type cast
          if (value is List) {
            errorMessage += '\n$key: ${value.join(', ')}';
          } else {
            errorMessage += '\n$key: $value'; // Handle non-List values
          }
        });
      }
      print('Failed to load user profile: $errorMessage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $errorMessage')),
        );
      }
      setState(() {
        _currentUser = null; // Ensure _currentUser is null on error
      });
    }
  }

  // Modified _logout to include a confirmation dialog
  void _logout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Konfirmasi Logout',
          ), // Using default TextStyle or AppTextStyles.normal
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
          ), // Using default TextStyle or AppTextStyles.normal
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Tidak',
                style: TextStyle(color: Colors.redAccent), // Specific color
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF624F82,
                ), // Matching the example's button color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ya'), // Using default TextStyle
            ),
          ],
        );
      },
    );

    if (confirmed != null && confirmed) {
      await ApiService.clearToken(); // Clear token using ApiService static method
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Anda telah logout.')));
      }
    }
  }

  void _navigateToEditProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not loaded yet. Please wait.')),
      );
      return;
    }

    // Navigate to the EditProfileScreen, passing the current user data.
    // Await the result to know if data was updated.
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUser: _currentUser!),
      ),
    );

    // If result is true, it means the profile was successfully updated in EditProfileScreen,
    // so refresh the data on this ProfileScreen.
    if (result == true) {
      _loadUserData(); // Refresh profile data
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provide default values if _currentUser is null (e.g., still loading or no user logged in)
    final String username = _currentUser?.name ?? 'Guest User';
    final String email = _currentUser?.email ?? 'guest@example.com';
    final String jenisKelamin = _currentUser?.jenis_kelamin == 'L'
        ? 'Laki-laki'
        : _currentUser?.jenis_kelamin == 'P'
        ? 'Perempuan'
        : 'N/A';
    final String profilePhotoUrl = _currentUser?.profile_photo ?? '';

    // Use training_title from API for designation (or use batch.name if preferred)
    final String designation = _currentUser?.training?.title ?? 'Employee';

    // Format the joinedDate based on batch.start_date from User model
    String formattedJoinedDate = 'N/A';
    if (_currentUser?.batch?.startDate != null) {
      try {
        final DateTime startDate = DateTime.parse(
          _currentUser!.batch!.startDate!,
        );
        formattedJoinedDate = DateFormat('MMM dd, yyyy').format(startDate);
      } catch (e) {
        print('Error parsing batch start date: $e');
        formattedJoinedDate = 'N/A';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya', // Updated to 'Profil Saya'
          style: TextStyle(
            color: Color(0xFF624F82), // Matching the example
            fontWeight: FontWeight.bold, // Added bold
            fontSize: 20, // Adjusted font size for AppBar title
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Managed by MainBottomNavigationBar
      ),
      extendBodyBehindAppBar: true, // Extend body behind transparent AppBar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0BBE4), // Light purple/pink
              Color(0xFFADD8E6), // Light blue
              Color(0xFF957DAD), // Medium purple
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white, // White loading indicator
                ),
              )
            : ListView(
                padding: EdgeInsets.only(
                  top:
                      AppBar().preferredSize.height +
                      MediaQuery.of(context).padding.top +
                      20, // Adjust top padding to clear AppBar
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                children: [
                  Center(
                    child: Column(
                      children: [
                        _buildProfileAvatar(profilePhotoUrl),
                        const SizedBox(height: 20),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White for username
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors
                                .white70, // Slightly transparent white for email
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  _buildProfileCard(
                    title: 'Informasi Pribadi',
                    children: [
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        label: 'Jenis Kelamin',
                        value: jenisKelamin,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildProfileCard(
                    title: 'Informasi Akademik/Training',
                    children: [
                      _buildInfoRow(
                        icon: Icons.group,
                        label: 'Batch',
                        value: _currentUser?.batch?.batch_ke ?? 'N/A',
                      ),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Mulai Batch',
                        value: _currentUser?.batch?.startDate != null
                            ? DateFormat('dd/MM/yyyy').format(
                                DateTime.parse(_currentUser!.batch!.startDate!),
                              )
                            : 'N/A',
                      ),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Akhir Batch',
                        value: _currentUser?.batch?.endDate != null
                            ? DateFormat('dd/MM/yyyy').format(
                                DateTime.parse(_currentUser!.batch!.endDate!),
                              )
                            : 'N/A',
                      ),
                      _buildInfoRow(
                        icon: Icons.school,
                        label: 'Training',
                        value: _currentUser?.training?.title ?? 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Edit Profile Button
                  ElevatedButton.icon(
                    onPressed: _navigateToEditProfile,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Profil',
                      style: TextStyle(fontSize: 18), // Adjusted font size
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF624F82,
                      ), // Primary button color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Logout Button (with confirmation)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _logout(context), // Call _logout with context
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xFF624F82),
                    ), // Icon color
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 18), // Adjusted font size
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white, // White background for logout button
                      foregroundColor: const Color(0xFF624F82), // Text color
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Helper Widgets (Modified/New) ---

  Widget _buildProfileAvatar(String profilePhotoPath) {
    ImageProvider<Object>? imageProvider;

    if (profilePhotoPath.isNotEmpty) {
      final String fullImageUrl = profilePhotoPath.startsWith('http')
          ? profilePhotoPath
          : 'https://appabsensi.mobileprojp.com/public/' + profilePhotoPath;
      imageProvider = NetworkImage(fullImageUrl);
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 65, // Adjust radius for visual appeal
        backgroundColor: Colors.white, // White background for the avatar area
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? const Icon(
                Icons.person,
                size: 80, // Larger icon
                color: Color(
                  0xB3624F82,
                ), // 70% opacity of example's primary color (approx)
              )
            : null,
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.white.withOpacity(0.95), // Slightly transparent white
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF624F82), // Matching the example
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(
              0x26957DAD,
            ), // 15% opacity of example's icon background
            child: Icon(icon, color: const Color(0xFF957DAD), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333), // Dark grey text
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
