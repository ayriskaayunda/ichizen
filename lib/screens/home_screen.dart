import 'dart:async';

import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/screens/attendance/request_screen.dart';
import 'package:ichizen/screens/main_bottom_navigation_bar.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; // For reverse geocoding
import 'package:geolocator/geolocator.dart'; // For geolocation
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;
  const HomeScreen({super.key, required this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String _userName = 'User';
  String _location = 'Getting Location...';
  String _currentDate = '';
  String _currentTime = '';
  Timer? _timer;

  AbsenceToday? _todayAbsence; // Changed from AttendanceModel to AbsenceToday
  AbsenceStats? _absenceStats; // New state for attendance statistics

  Position? _currentPosition;
  bool _permissionGranted = false;
  bool _isCheckingInOrOut = false; // To prevent multiple taps during API calls

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _determinePosition(); // Start location fetching
    _loadUserData();
    _fetchAttendanceData(); // Fetch initial attendance data

    widget.refreshNotifier.addListener(_handleRefreshSignal);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _fetchAttendanceData(); // Re-fetch data for the home screen
      widget.refreshNotifier.value = false; // Reset the notifier after handling
    }
  }

  Future<void> _loadUserData() async {
    final ApiResponse<User> response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _userName = response.data!.name;
      });
    } else {
      print('Failed to load user profile: ${response.message}');
      setState(() {
        _userName = 'User'; // Default if profile fails
      });
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      if (mounted) {
        _showErrorDialog('Location services are disabled. Please enable them.');
      }
      setState(() {
        _location = 'Location services disabled';
        _permissionGranted = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        if (mounted) {
          _showErrorDialog(
            'Location permissions are denied. Please grant them in settings.',
          );
        }
        setState(() {
          _location = 'Location permissions denied';
          _permissionGranted = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      if (mounted) {
        _showErrorDialog(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
      setState(() {
        _location = 'Location permissions permanently denied';
        _permissionGranted = false;
      });
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _permissionGranted = true;
      });
      await _getAddressFromLatLng(position);
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        _showErrorDialog('Failed to get current location: $e');
      }
      setState(() {
        _location = 'Failed to get location';
        _permissionGranted = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      setState(() {
        _location =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print('Error getting address from coordinates: $e');
      setState(() {
        _location = 'Address not found';
      });
    }
  }

  Future<void> _fetchAttendanceData() async {
    // Fetch today's absence record
    final ApiResponse<AbsenceToday> todayAbsenceResponse = await _apiService
        .getAbsenceToday();
    if (todayAbsenceResponse.statusCode == 200 &&
        todayAbsenceResponse.data != null) {
      setState(() {
        _todayAbsence = todayAbsenceResponse.data;
      });
    } else {
      print('Failed to get today\'s absence: ${todayAbsenceResponse.message}');
      setState(() {
        _todayAbsence = null; // Reset if no record or error
      });
    }

    // Fetch attendance statistics
    final ApiResponse<AbsenceStats> statsResponse = await _apiService
        .getAbsenceStats();
    if (statsResponse.statusCode == 200 && statsResponse.data != null) {
      setState(() {
        _absenceStats = statsResponse.data;
      });
    } else {
      print('Failed to get absence stats: ${statsResponse.message}');
      setState(() {
        _absenceStats = null; // Reset if no stats or error
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition(); // Try to get location again
      return;
    }
    if (_isCheckingInOrOut) return; // Prevent double tap

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      // Format the current time to 'HH:mm' string for the API
      final String formattedCheckInTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkIn(
        checkInLat: _currentPosition!.latitude,
        checkInLng: _currentPosition!.longitude,
        checkInAddress: _location,
        status: 'masuk', // Assuming 'masuk' for regular check-in
        attendanceDate: formattedAttendanceDate,
        checkInTime: formattedCheckInTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        _fetchAttendanceData(); // Refresh home after check-in
        MainBottomNavigationBar.refreshAttendanceNotifier.value =
            true; // Signal AttendanceListScreen
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
        if (mounted) {
          _showErrorDialog('Check In Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-in: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition(); // Try to get location again
      return;
    }
    if (_isCheckingInOrOut) return; // Prevent double tap

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      // Format the current time to 'HH:mm' string for the API
      final String formattedCheckOutTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkOut(
        checkOutLat: _currentPosition!.latitude,
        checkOutLng: _currentPosition!.longitude,
        checkOutAddress: _location,
        attendanceDate: formattedAttendanceDate,
        checkOutTime: formattedCheckOutTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        _fetchAttendanceData(); // Refresh home after check-out
        MainBottomNavigationBar.refreshAttendanceNotifier.value =
            true; // Signal AttendanceListScreen
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
        if (mounted) {
          _showErrorDialog('Check Out Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-out: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  String _calculateWorkingHours() {
    if (_todayAbsence == null || _todayAbsence!.jamMasuk == null) {
      return '00:00:00'; // No check-in yet or jamMasuk is null
    }

    final DateTime checkInDateTime =
        _todayAbsence!.jamMasuk!; // Null-check added
    DateTime endDateTime;

    if (_todayAbsence!.jamKeluar != null) {
      endDateTime = _todayAbsence!.jamKeluar!; // Null-check added
    } else {
      endDateTime = DateTime.now(); // Use current time for live calculation
    }

    final Duration duration = endDateTime.difference(checkInDateTime);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;

    // Define the gradient colors for the overall background
    const List<Color> gradientColors = [
      Color(0xFFE0BBE4), // AppColor.gradientLightStart (approx)
      Color(0xFFADD8E6), // Middle color (approx)
      Color(0xFF957DAD), // AppColor.gradientLightEnd (approx)
    ];

    return Scaffold(
      // Remove AppBar from Scaffold to create a custom header within the body
      // backgroundColor: AppColors.background, // Will be covered by gradient container
      body: Container(
        // Ensure the container fills the entire screen
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Header Section (mimicking HomePage's profile)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30, // Adjusted size
                          // Placeholder image, as original HomeScreen doesn't fetch profile photo URL
                          backgroundImage: NetworkImage(
                            'https://placehold.co/100x100/007bff/ffffff?text=${_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U'}',
                          ),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $_userName!',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              // Display location here, as it's part of the existing state
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _location,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Notification Icon (from original AppBar)
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            // Handle notification button press (existing logic)
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Status Kehadiran Hari Ini Card (Main Action Card)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: EdgeInsets.zero, // Remove default card margin
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Kehadiran Hari Ini',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    AppColors.textDark, // Using existing color
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentTime,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      _currentDate,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: _isCheckingInOrOut
                                      ? null
                                      : (hasCheckedIn
                                            ? (hasCheckedOut
                                                  ? null
                                                  : _handleCheckOut)
                                            : _handleCheckIn),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasCheckedIn
                                        ? (hasCheckedOut
                                              ? Colors
                                                    .grey // Checked Out
                                              : Colors
                                                    .redAccent) // Ready for Check Out
                                        : Colors.green, // Ready for Check In
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 25,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: _isCheckingInOrOut
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          hasCheckedIn
                                              ? (hasCheckedOut
                                                    ? 'Checked Out'
                                                    : 'Check Out')
                                              : 'Check In',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTimeDetail(
                                  Icons.watch_later_outlined,
                                  _todayAbsence?.jamMasuk
                                          ?.toLocal()
                                          .toString()
                                          .substring(11, 16) ??
                                      'N/A', // Format to HH:mm
                                  'Check In',
                                  AppColors.primary,
                                ),
                                _buildTimeDetail(
                                  Icons.watch_later_outlined,
                                  _todayAbsence?.jamKeluar
                                          ?.toLocal()
                                          .toString()
                                          .substring(11, 16) ??
                                      'N/A', // Format to HH:mm
                                  'Check Out',
                                  Colors.redAccent,
                                ),
                                _buildTimeDetail(
                                  Icons.watch_later_outlined,
                                  _calculateWorkingHours(),
                                  'Working HR\'s',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Attendance Summary Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0.0,
                      ), // Adjusted padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Kehadiran Bulan Ini', // Changed title
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              _buildSummaryCard(
                                'Hadir', // Changed label
                                _absenceStats?.totalMasuk ?? 0,
                                Colors.green,
                              ),
                              const SizedBox(width: 10),
                              _buildSummaryCard(
                                'Izin/Sakit', // Changed label
                                _absenceStats?.totalIzin ?? 0,
                                Colors
                                    .orange, // Changed color to orange for Izin/Sakit
                              ),
                              const SizedBox(width: 10),
                              _buildSummaryCard(
                                'Tidak Hadir', // Changed label
                                _absenceStats?.totalAbsen ?? 0,
                                Colors
                                    .red, // Changed color to red for Tidak Hadir
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 80,
                    ), // Space for the positioned button
                  ],
                ),
              ),
              // Request Button (Positioned at the bottom)
              Positioned(
                bottom: 16, // Adjusted slightly for better spacing
                left: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RequestScreen()),
                    );
                    if (result == true) {
                      _fetchAttendanceData(); // Refresh home after request
                      MainBottomNavigationBar.refreshAttendanceNotifier.value =
                          true; // Signal AttendanceListScreen
                    }
                  },
                  icon: const Icon(
                    Icons.add_task,
                    color: Colors.white,
                  ), // Icon color white
                  label: const Text(
                    'Ajukan Permintaan', // Changed label
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ), // Text color white
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary, // Primary color as background
                    foregroundColor: Colors.white, // Text/icon color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5, // Added elevation for more prominence
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for time details (Check In, Check Out, Working Hours)
  Widget _buildTimeDetail(
    IconData icon,
    String time,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  // Helper widget for attendance summary cards
  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white, // Card background color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3, // Slightly increased elevation
        child: Column(
          children: [
            Container(
              height: 5.0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12.0,
                12.0,
                12.0,
                12.0,
              ), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      count.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
