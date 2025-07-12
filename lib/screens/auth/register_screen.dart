import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/constants/app_text_styles.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/routes/app_routes.dart';
import 'package:ichizen/services/api_services.dart';
// import 'package:ichizen/widgets/custom_dropdown_input_field.dart'; // Tidak digunakan lagi untuk styling
// import 'package:ichizen/widgets/custom_input_field.dart'; // Tidak digunakan lagi untuk styling
// import 'package:ichizen/widgets/primary_button.dart'; // Tidak digunakan lagi untuk styling
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Diperlukan untuk Text.rich

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ApiService _apiService = ApiService(); // Instantiate your ApiService

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; // Add loading state

  List<Batch> _batches = []; // Keep this to fetch batches and find "Batch 2"
  List<Training> _trainings = [];
  int? _selectedBatchId;
  String _selectedBatchName =
      'Loading Batch...'; // To display the selected batch (will be replaced by dropdown)
  int? _selectedTrainingId;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch Batches
    try {
      final batchResponse = await _apiService.getBatches();
      if (batchResponse.statusCode == 200 && batchResponse.data != null) {
        setState(() {
          _batches = batchResponse.data!;
          // Automatically select "Batch 2" if found, otherwise select the first available batch
          final batch2 = _batches.firstWhere(
            (batch) => batch.batch_ke == '2', // Correctly using batch.batch_ke
            orElse: () => _batches.isNotEmpty
                ? _batches.first
                : Batch(
                    id: -1,
                    batch_ke: 'N/A',
                    startDate: '',
                    endDate: '',
                  ), // Corrected Batch constructor
          );
          _selectedBatchId = batch2.id;
          _selectedBatchName =
              'Batch ${batch2.batch_ke}'; // Display as "Batch 2"
        });
      } else {
        if (mounted) {
          final String message = batchResponse.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load batches: $message')),
          );
        }
        setState(() {
          _selectedBatchName = 'Error Loading Batch';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while fetching batches: $e'),
          ),
        );
      }
      setState(() {
        _selectedBatchName = 'Error Loading Batch';
      });
    }

    // Fetch Trainings
    try {
      final trainingResponse = await _apiService.getTrainings();
      if (trainingResponse.statusCode == 200 && trainingResponse.data != null) {
        setState(() {
          _trainings = trainingResponse.data!;
        });
      } else {
        if (mounted) {
          final String message = trainingResponse.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load trainings: $message')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while fetching trainings: $e'),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBatchId == null || _selectedBatchId == -1) {
        // Check for valid batch ID
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch not selected or invalid.')),
        );
        return;
      }
      if (_selectedTrainingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a training')),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }
      if (_selectedGender == null) {
        // Added validation for gender
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender')),
        );
        return;
      }

      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Call the register method from ApiService
      final ApiResponse<AuthData> response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        batchId: _selectedBatchId!,
        trainingId: _selectedTrainingId!,
        jenisKelamin: _selectedGender!,
      );

      setState(() {
        _isLoading = false; // Set loading to false
      });

      if (response.statusCode == 200 && response.data != null) {
        // Registration successful
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // Registration failed, show error message
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Tetap dipertahankan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Akun'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0BBE4), Color(0xFFADD8E6), Color(0xFF957DAD)],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              SizedBox(height: AppBar().preferredSize.height + 20),

              // Title and Subtitle
              Text(
                "Create Account",
                style: AppTextStyles.heading.copyWith(
                  color:
                      Colors.white, // Changed to white for gradient background
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Join us to track your attendance effortlessly.",
                style: AppTextStyles.normal.copyWith(
                  color: Colors.white70, // Slightly transparent white
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Nama Lengkap
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "Masukkan nama lengkap Anda",
                  hintStyle: TextStyle(color: Colors.white70.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "Masukkan email Anda",
                  hintStyle: TextStyle(color: Colors.white70.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "Buat password Anda",
                  hintStyle: TextStyle(color: Colors.white70.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Confirm Password (DIPERTAHANKAN SESUAI KODE ASLI ANDA)
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "Konfirmasi password Anda",
                  hintStyle: TextStyle(color: Colors.white70.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != _passwordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Jenis Kelamin Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Jenis Kelamin',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Pilih Jenis Kelamin',
                  hintStyle: TextStyle(color: Colors.white70.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  prefixIcon: const Icon(
                    Icons.transgender,
                    color: Colors.white70,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                ),
                dropdownColor: const Color(
                  0xFF624F82,
                ), // Warna background dropdown menu
                style: const TextStyle(
                  color: Colors.white,
                ), // Warna teks item yang dipilih
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(
                    value: 'L',
                    child: Text(
                      'Laki-laki',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'P',
                    child: Text(
                      'Perempuan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih jenis kelamin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Batch Dropdown (sekarang menjadi dropdown, bukan teks statis)
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Batch',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Pilih Batch',
                        hintStyle: TextStyle(
                          color: Colors.white70.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        prefixIcon: const Icon(
                          Icons.group,
                          color: Colors.white70,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                      ),
                      dropdownColor: const Color(0xFF624F82),
                      style: const TextStyle(color: Colors.white),
                      value: _selectedBatchId,
                      isExpanded: true,
                      items: _batches.map((batch) {
                        return DropdownMenuItem<int>(
                          value: batch.id,
                          child: Text(
                            'Batch ${batch.batch_ke}',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedBatchId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value == -1) {
                          // Check for -1 from orElse
                          return 'Pilih batch';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16.0),

              // Training Dropdown
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Training',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Pilih Training',
                        hintStyle: TextStyle(
                          color: Colors.white70.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        prefixIcon: const Icon(
                          Icons.school,
                          color: Colors.white70,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                      ),
                      dropdownColor: const Color(0xFF624F82),
                      style: const TextStyle(color: Colors.white),
                      value: _selectedTrainingId,
                      isExpanded: true,
                      items: _trainings.map((training) {
                        return DropdownMenuItem<int>(
                          value: training.id,
                          child: Text(
                            training.title,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedTrainingId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih training';
                        }
                        return null;
                      },
                      menuMaxHeight: 300.0,
                    ),
              const SizedBox(height: 24.0),

              // Register Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF624F82),
                      ),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
              const SizedBox(height: 16.0),

              // Login Link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Sudah punya akun? ',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC0A4E3), // Warna link login
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
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
