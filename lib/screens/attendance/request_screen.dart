import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart'; // Ensure correct import for app_models.dart
import 'package:ichizen/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

// Hapus import untuk CustomDateInputField, CustomInputField, PrimaryButton
// import '../../widgets/custom_date_input_field.dart';
// import '../../widgets/custom_input_field.dart';
// import '../../widgets/primary_button.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  DateTime? _selectedDate;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    // No location-related initialization needed
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textDark, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    // Basic validation
    if (_selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }
    if (_reasonController.text.isEmpty) {
      _showSnackBar('Please enter a reason for the request.');
      return;
    }

    setState(() {
      _isLoading = true; // Set loading to true
    });

    try {
      // Format the selected date to yyyy-MM-dd as required by the /izin API
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);

      // Call the dedicated submitIzinRequest method from ApiService
      final ApiResponse<Absence> response = await _apiService.submitIzinRequest(
        date: formattedDate, // Pass the formatted date as 'date'
        alasanIzin: _reasonController.text.trim(), // Only send the reason text
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSnackBar('Request submitted successfully!');
          Navigator.pop(context, true); // Pop with true to indicate success
        }
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
          _showSnackBar('Failed to submit request: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred: $e');
      }
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      // Latar belakang gradien penuh
      body: Container(
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
          // Memastikan konten tidak tumpang tindih dengan sistem UI
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Ajukan Permintaan Baru', // Judul baru
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 48,
                    ), // Untuk menyeimbangkan tombol kembali
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date Picker
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          // Mencegah keyboard muncul saat tap
                          child: TextFormField(
                            controller: TextEditingController(
                              text: _selectedDate != null
                                  ? DateFormat(
                                      'dd MMMM yyyy',
                                    ).format(_selectedDate!)
                                  : '',
                            ),
                            readOnly: true, // Membuat field hanya bisa dibaca
                            decoration: InputDecoration(
                              labelText: 'Pilih Tanggal', // Label baru
                              hintText:
                                  'Belum ada tanggal dipilih', // Hint baru
                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide.none, // Menghilangkan border
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(
                                0.9,
                              ), // Warna fill
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            validator: (value) {
                              if (_selectedDate == null) {
                                return 'Tanggal tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Reason Text Field
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 5, // Lebih banyak baris untuk alasan
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Alasan Permintaan', // Label baru
                          hintText:
                              'Cth: Cuti tahunan, izin sakit, keperluan pribadi', // Hint baru
                          prefixIcon: const Icon(
                            Icons.edit_note,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none, // Menghilangkan border
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(
                            0.9,
                          ), // Warna fill
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alasan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Submit Button
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitRequest,
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ), // Icon kirim
                                label: const Text(
                                  'Kirim Permintaan', // Teks tombol baru
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      30,
                                    ), // Bentuk pil
                                  ),
                                  elevation: 5,
                                ),
                              ),
                            ),
                    ],
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
