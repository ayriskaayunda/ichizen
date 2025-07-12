import 'dart:async';

import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/screens/main_bottom_navigation_bar.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Make sure intl package is in pubspec.yaml

class AttendanceListScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const AttendanceListScreen({super.key, required this.refreshNotifier});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Absence>>
  _attendanceFuture; // Changed to Future<List<Absence>>

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _fetchAndFilterAttendances();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      print(
        'AttendanceListScreen: Refresh signal received, refreshing list...',
      );
      _refreshList();
      widget.refreshNotifier.value = false;
    }
  }

  Future<List<Absence>> _fetchAndFilterAttendances() async {
    // Format the start and end dates for the API call
    final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
    final String endDate = DateFormat('yyyy-MM-dd').format(
      DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      ), // Last day of the month
    );

    try {
      final ApiResponse<List<Absence>> response = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      if (response.statusCode == 200 && response.data != null) {
        final List<Absence> fetchedAbsences = response.data!;
        // Sort by attendanceDate in descending order (latest first)
        fetchedAbsences.sort((a, b) {
          // Handle null attendanceDate dates: nulls come last
          if (a.attendanceDate == null && b.attendanceDate == null) return 0;
          if (a.attendanceDate == null)
            return 1; // a is null, b is not, a comes after b
          if (b.attendanceDate == null)
            return -1; // b is null, a is not, b comes after a
          return b.attendanceDate!.compareTo(
            a.attendanceDate!,
          ); // Both are non-null, compare
        });
        return fetchedAbsences;
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
        throw Exception(errorMessage); // Throw the safely constructed message
      }
    } catch (e) {
      print('Error fetching and filtering attendance list: $e');
      // Show a SnackBar for the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance: $e')),
        );
      }
      return []; // Return an empty list on error
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      _attendanceFuture = _fetchAndFilterAttendances();
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Using your AppColors.primary
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final DateTime newSelectedMonth = DateTime(picked.year, picked.month, 1);
      if (newSelectedMonth.year != _selectedMonth.year ||
          newSelectedMonth.month != _selectedMonth.month) {
        setState(() {
          _selectedMonth = newSelectedMonth;
        });
        _refreshList();
      }
    }
  }

  String _calculateWorkingHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) {
      return '00:00:00';
    }

    DateTime endDateTime =
        checkOut ?? DateTime.now(); // Use current time if no checkout

    final Duration duration = endDateTime.difference(checkIn);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper widget to build time rows (Check-in, Check-out)
  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required DateTime? time,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(
          '$label: ${time != null ? DateFormat('HH:mm').format(time) : 'Belum Check-out'}',
          style: TextStyle(
            fontSize: 17,
            color: time != null ? Colors.black87 : Colors.orange.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Modified _buildAttendanceTile to match the example's card design
  Widget _buildAttendanceTile(Absence absence) {
    // Determine if it's a request type based on 'status' being 'izin'
    bool isRequestType = absence.status?.toLowerCase() == 'izin';

    // Determine the status text and color based on absence status
    String statusText;
    Color statusColor;
    if (isRequestType) {
      statusText = 'IZIN';
      statusColor = AppColors.accentOrange; // Or a specific color for 'Izin'
    } else if (absence.status?.toLowerCase() == 'late') {
      statusText = 'TERLAMBAT';
      statusColor = AppColors.accentRed;
    } else if (absence.status?.toLowerCase() == 'masuk' &&
        absence.checkOut != null) {
      statusText = 'SELESAI'; // Checked in and out
      statusColor = AppColors.accentGreen;
    } else if (absence.status?.toLowerCase() == 'masuk' &&
        absence.checkIn != null) {
      statusText = 'CHECK IN HARI INI'; // Only checked in
      statusColor = Colors.blue; // A distinct color for ongoing check-in
    } else {
      statusText = 'N/A';
      statusColor = Colors.grey;
    }

    final DateTime? displayDate = absence.attendanceDate;
    final String formattedDate = displayDate != null
        ? DateFormat('EEEE, dd MMMM yyyy').format(displayDate)
        : 'N/A'; // Fallback for date

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.85), // Slightly transparent white
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF624F82), // Matching example's title color
                  ),
                ),
                // Display status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1.5, color: Colors.grey),
            // Conditionally display check-in/out times or reason
            if (!isRequestType) // Only show check-in/out for non-izin types
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeRow(
                    icon: Icons.login,
                    label: 'Check-in',
                    time: absence.checkIn,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeRow(
                    icon: Icons.logout,
                    label: 'Check-out',
                    time: absence.checkOut,
                    color: Colors.red,
                  ),
                  if (absence.checkIn !=
                      null) // Only show working hours if checked in
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.blueGrey,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Jam Kerja: ${_calculateWorkingHours(absence.checkIn, absence.checkOut)}',
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            else // For 'izin' type, only show reason
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Alasan: ${absence.alasanIzin?.isNotEmpty == true ? absence.alasanIzin : 'Tidak ada alasan'}', // Display the reason, handle empty string
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16, // Slightly larger font for reason
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define the gradient colors for the overall background
    const List<Color> gradientColors = [
      Color(0xFFE0BBE4), // AppColor.gradientLightStart (approx)
      Color(0xFFADD8E6), // Middle color (approx)
      Color(0xFF957DAD), // AppColor.gradientLightEnd (approx)
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Kehadiran', // Matching example's title
          style: TextStyle(
            color: Color(0xFF624F82), // Matching example's title color
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(
          0xFF624F82,
        ), // Matching example's foreground
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true, // Extend body behind transparent AppBar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Padding to push content below the transparent AppBar
            Padding(
              padding: EdgeInsets.only(
                top:
                    AppBar().preferredSize.height +
                    MediaQuery.of(context).padding.top +
                    16.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Kehadiran Bulanan', // Updated title for clarity
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark, // Using existing color
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectMonth(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withOpacity(
                          0.5,
                        ), // Semi-transparent for style
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat(
                              'MMM yyyy', // Display month and year
                            ).format(_selectedMonth).toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0), // Spacing after month selector
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshList,
                color: AppColors.primary, // Color of the refresh indicator
                child: FutureBuilder<List<Absence>>(
                  future: _attendanceFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final attendances = snapshot.data ?? [];

                    if (attendances.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada riwayat kehadiran untuk ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 16.0,
                      ), // Padding for the bottom of the list
                      itemCount: attendances.length,
                      itemBuilder: (context, index) {
                        return _buildAttendanceTile(attendances[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
