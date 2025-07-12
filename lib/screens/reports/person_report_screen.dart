import 'dart:async';

import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonReportScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const PersonReportScreen({super.key, required this.refreshNotifier});

  @override
  State<PersonReportScreen> createState() => _PersonReportScreenState();
}

class _PersonReportScreenState extends State<PersonReportScreen> {
  final ApiService _apiService = ApiService();

  late Future<void>
  _reportDataFuture; // Changed to void as we update state directly
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  // Summary counts for the selected month - Initialized directly to avoid LateInitializationError
  int _presentCount = 0;
  int _absentCount =
      0; // Will now include all non-regular attendance types (izin)
  int _lateInCount = 0; // Mapped from total_absen in AbsenceStats
  int _totalWorkingDaysInMonth =
      0; // Will be derived from presentCount for simplicity
  String _totalWorkingHours = '0hr';

  // Data for Pie Chart
  List<PieChartSectionData> _pieChartSections = [];

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _fetchAndCalculateMonthlyReports();

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
        'PersonReportScreen: Refresh signal received, refreshing reports...',
      );
      setState(() {
        _reportDataFuture = _fetchAndCalculateMonthlyReports();
      });
      widget.refreshNotifier.value = false;
    }
  }

  // Fetches attendance data and calculates monthly summaries
  Future<void> _fetchAndCalculateMonthlyReports() async {
    try {
      // 1. Fetch Absence Stats for summary counts
      final ApiResponse<AbsenceStats> statsResponse = await _apiService
          .getAbsenceStats();
      if (statsResponse.statusCode == 200 && statsResponse.data != null) {
        final AbsenceStats stats = statsResponse.data!;
        setState(() {
          _presentCount = stats.totalMasuk;
          _absentCount = stats
              .totalIzin; // Assuming total_izin covers all types of absences/leaves
          _lateInCount =
              stats.totalAbsen; // Assuming total_absen covers late entries
          _totalWorkingDaysInMonth = stats
              .totalMasuk; // Simplified: Total working days = total present days
        });
      } else {
        print('Failed to get absence stats: ${statsResponse.message}');
        _updateSummaryCounts(0, 0, 0, 0, '0hr'); // Reset counts on error
        _updatePieChartData(0, 0, 0); // Reset pie chart data on error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load summary: ${statsResponse.message}'),
            ),
          );
        }
        return; // Exit if stats fetching fails
      }

      // 2. Fetch Absence History for total working hours calculation
      final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final String endDate = DateFormat('yyyy-MM-dd').format(
        DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
          0,
        ), // Last day of the month
      );

      final ApiResponse<List<Absence>> historyResponse = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      Duration totalWorkingDuration = Duration.zero;
      if (historyResponse.statusCode == 200 && historyResponse.data != null) {
        for (var absence in historyResponse.data!) {
          // Only count working hours for 'masuk' entries that have both checkIn and checkOut
          if (absence.status?.toLowerCase() ==
                  'masuk' && // Safely call toLowerCase
              absence.checkIn != null && // Added null check for checkIn
              absence.checkOut != null) {
            totalWorkingDuration += absence.checkOut!.difference(
              absence.checkIn!, // Added null assertion for checkIn
            );
          }
        }
      } else {
        print(
          'Failed to get absence history for working hours: ${historyResponse.message}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load working hours: ${historyResponse.message}',
              ),
            ),
          );
        }
      }

      final int totalHours = totalWorkingDuration.inHours;
      final int remainingMinutes = totalWorkingDuration.inMinutes.remainder(60);
      String formattedTotalWorkingHours =
          '${totalHours}hr ${remainingMinutes}min';

      setState(() {
        _totalWorkingHours = formattedTotalWorkingHours;
      });

      // Update pie chart data after all counts are finalized
      _updatePieChartData(_presentCount, _absentCount, _lateInCount);
    } catch (e) {
      print('Error fetching and calculating monthly reports: $e');
      _updateSummaryCounts(0, 0, 0, 0, '0hr'); // Reset counts on error
      _updatePieChartData(0, 0, 0); // Reset pie chart data on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred loading reports: $e')),
        );
      }
    }
  }

  // Updates the state variables for summary counts
  void _updateSummaryCounts(
    int present,
    int absent,
    int late,
    int totalWorkingDays,
    String totalHrs,
  ) {
    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _lateInCount = late;
      _totalWorkingDaysInMonth = totalWorkingDays;
      _totalWorkingHours = totalHrs;
    });
  }

  // New method to update pie chart data
  void _updatePieChartData(int presentCount, int absentCount, int lateInCount) {
    final total = presentCount + absentCount + lateInCount;
    if (total == 0) {
      setState(() {
        _pieChartSections = [];
      });
      return;
    }

    const Color presentColor = Colors.green;
    const Color absentColor = Colors.red;
    const Color lateColor = Colors.orange;

    setState(() {
      _pieChartSections = [
        if (presentCount > 0)
          PieChartSectionData(
            color: presentColor,
            value: presentCount.toDouble(),
            title: '${(presentCount / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _buildBadge('Present', presentColor),
            badgePositionPercentageOffset: .98,
          ),
        if (absentCount > 0)
          PieChartSectionData(
            color: absentColor,
            value: absentCount.toDouble(),
            title: '${(absentCount / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _buildBadge('Absent', absentColor),
            badgePositionPercentageOffset: .98,
          ),
        if (lateInCount > 0)
          PieChartSectionData(
            color: lateColor,
            value: lateInCount.toDouble(),
            title: '${(lateInCount / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _buildBadge('Late', lateColor),
            badgePositionPercentageOffset: .98,
          ),
      ];
    });
  }

  // Helper for PieChart badges (labels)
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Method to show month picker (only month and year)
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
      initialDatePickerMode: DatePickerMode.year, // Start with year selection
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
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
          _reportDataFuture =
              _fetchAndCalculateMonthlyReports(); // Trigger re-fetch
        });
      }
    }
  }

  // Helper widget to build summary cards
  Widget _buildSummaryCard(String title, dynamic value, Color color) {
    return Card(
      color: Colors.white.withOpacity(0.9), // Slightly transparent white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ), // Rounded corners
      elevation: 5, // Added elevation
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Adjusted padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 28, // Adjusted font size
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
      Color(0xFFE0BBE4), // Light purple/pink
      Color(0xFFADD8E6), // Light blue
      Color(0xFF957DAD), // Medium purple
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Kehadiran', // Mengubah judul
          style: TextStyle(
            color: Color(0xFF624F82), // Warna teks sesuai tema
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent, // Transparan
        elevation: 0, // Tanpa bayangan
        centerTitle: true, // Judul di tengah
      ),
      extendBodyBehindAppBar: true, // Memperpanjang body di belakang AppBar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: FutureBuilder<void>(
          future: _reportDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
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

            // Data is loaded, build the UI
            return RefreshIndicator(
              onRefresh:
                  _fetchAndCalculateMonthlyReports, // Enable pull-to-refresh
              color: AppColors.primary,
              child: ListView(
                padding: EdgeInsets.only(
                  top:
                      AppBar().preferredSize.height +
                      MediaQuery.of(context).padding.top +
                      16.0, // Padding untuk menghindari AppBar
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                children: [
                  // Month selection
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ringkasan Bulanan', // Mengubah judul
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark, // Warna teks
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
                              ), // Semi-transparan
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat(
                                    'MMM yyyy', // Format bulan dan tahun
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
                  // Summary cards for the selected month in a 3x2 grid
                  GridView.count(
                    crossAxisCount: 2, // Mengubah menjadi 2 kolom
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16, // Spasi lebih besar
                    crossAxisSpacing: 16, // Spasi lebih besar
                    childAspectRatio: 1.5, // Mengubah rasio aspek
                    children: [
                      _buildSummaryCard(
                        'Total Hari Kerja', // Mengubah label
                        _totalWorkingDaysInMonth.toString().padLeft(2, '0'),
                        Colors.blueGrey,
                      ),
                      _buildSummaryCard(
                        'Total Hadir', // Mengubah label
                        _presentCount.toString().padLeft(2, '0'),
                        Colors.green,
                      ),
                      _buildSummaryCard(
                        'Total Izin/Absen', // Menggabungkan Izin dan Absen
                        (_absentCount + _lateInCount).toString().padLeft(
                          2,
                          '0',
                        ), // Menjumlahkan
                        Colors.red,
                      ),
                      _buildSummaryCard(
                        'Total Jam Kerja', // Mengubah label
                        _totalWorkingHours,
                        AppColors.primary,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      0.0,
                      30.0,
                      0.0,
                      15.0,
                    ), // Padding disesuaikan
                    child: Text(
                      'Rincian Status Kehadiran', // Mengubah judul
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  // Pie Chart
                  AspectRatio(
                    aspectRatio: 1.2, // Mengubah rasio aspek Pie Chart
                    child: Card(
                      color: Colors.white.withOpacity(
                        0.9,
                      ), // Latar belakang kartu Pie Chart
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PieChart(
                          PieChartData(
                            sections: _pieChartSections,
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        return;
                                      }
                                    });
                                  },
                            ),
                          ),
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
    );
  }
}
