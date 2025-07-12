// lib/services/api_service.dart
import 'dart:convert';

import 'package:ichizen/models/app_models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'https://appabsensi.mobileprojp.com/api';
  static String? _token;

  // Initialize token from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  // Save token to SharedPreferences
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
  }

  // Clear token from SharedPreferences
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
  }

  // Helper to get token (for external use, e.g., SplashScreen)
  static String? getToken() {
    return _token;
  }

  // Helper to get headers with Authorization token
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- Auth Endpoints ---

  // Updated Register method to match new API structure
  Future<ApiResponse<AuthData>> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'batch_id': batchId,
          'training_id': trainingId,
          'jenis_kelamin': jenisKelamin,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Pastikan responseBody['data'] tidak null sebelum di-parse
        final authResponse = AuthResponse.fromJson(responseBody);
        if (authResponse.data != null) {
          await _saveToken(authResponse.data!.token);
        }
        return ApiResponse(
          message: authResponse.message,
          data: authResponse.data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<AuthData>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Pastikan responseBody['data'] tidak null sebelum di-parse
        final authResponse = AuthResponse.fromJson(responseBody);
        if (authResponse.data != null) {
          await _saveToken(authResponse.data!.token);
        }
        return ApiResponse(
          message: authResponse.message,
          data: authResponse.data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Request OTP for Forgot Password
  Future<ApiResponse<void>> forgotPassword({required String email}) async {
    final url = Uri.parse('$_baseUrl/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'] ?? 'OTP requested successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to request OTP',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Verify OTP
  Future<ApiResponse<void>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$_baseUrl/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'] ?? 'OTP verified successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to verify OTP',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Reset Password
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final url = Uri.parse('$_baseUrl/reset-password');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'] ?? 'Password reset successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- Absence Endpoints ---

  // Modified checkIn to handle both 'masuk' and 'izin' statuses
  // Location parameters are now nullable as they are not needed for 'izin'
  Future<ApiResponse<Absence>> checkIn({
    double? checkInLat, // Made nullable
    double? checkInLng, // Made nullable
    String? checkInAddress, // Made nullable
    String? checkInTime,
    required String status, // "masuk" or "izin"
    String? alasanIzin, // Required if status is "izin"
    required String attendanceDate,
  }) async {
    final url = Uri.parse('$_baseUrl/absen/check-in');
    try {
      final body = <String, dynamic>{
        'status': status,
        'attendance_date': attendanceDate,
        'check_in': checkInTime,
      };

      if (status == 'masuk') {
        if (checkInLat != null) body['check_in_lat'] = checkInLat;
        if (checkInLng != null) body['check_in_lng'] = checkInLng;
        if (checkInAddress != null) body['check_in_address'] = checkInAddress;
        if (checkInTime != null) body['check_in'] = checkInTime;
      } else if (status == 'izin') {
        if (alasanIzin != null) body['alasan_izin'] = alasanIzin;
      }

      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? Absence.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Check-in failed',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<Absence>> checkOut({
    required double checkOutLat,
    required double checkOutLng,
    required String checkOutAddress,
    required String attendanceDate,
    required String checkOutTime,
  }) async {
    final url = Uri.parse('$_baseUrl/absen/check-out');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'check_out_lat': checkOutLat,
          'check_out_lng': checkOutLng,
          'check_out_address': checkOutAddress,
          'attendance_date': attendanceDate,
          'check_out': checkOutTime,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? Absence.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Check-out failed',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<AbsenceToday>> getAbsenceToday() async {
    final url = Uri.parse('$_baseUrl/absen/today');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? AbsenceToday.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get today\'s absence data',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<AbsenceStats>> getAbsenceStats() async {
    final url = Uri.parse('$_baseUrl/absen/stats');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? AbsenceStats.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get absence statistics',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<Absence>> deleteAbsence(int id) async {
    final url = Uri.parse('$_baseUrl/absen/$id');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? Absence.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to delete absence data',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<List<Absence>>> getAbsenceHistory({
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> queryParams = {};
    if (startDate != null) {
      queryParams['start'] = startDate;
    }
    if (endDate != null) {
      queryParams['end'] = endDate;
    }

    final url = Uri.parse(
      '$_baseUrl/absen/history',
    ).replace(queryParameters: queryParams);
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Perbaikan: Tambahkan null check dan pastikan tipe List
        List<Absence> history = (responseBody['data'] is List)
            ? (responseBody['data'] as List)
                  .map((e) => Absence.fromJson(e))
                  .toList()
            : []; // Return empty list if data is not a List or is null
        return ApiResponse(
          message: responseBody['message'],
          data: history,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get absence history',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- User Profile Endpoints ---

  Future<ApiResponse<User>> getProfile() async {
    final url = Uri.parse('$_baseUrl/profile');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? User.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get profile data',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // Modified: Update user name and gender
  Future<ApiResponse<User>> updateProfile({
    String? name, // Changed to optional
    String? jenisKelamin, // Changed to optional
  }) async {
    final url = Uri.parse('$_baseUrl/profile');
    try {
      final body = <String, dynamic>{};
      if (name != null) {
        body['name'] = name;
      }
      if (jenisKelamin != null) {
        body['jenis_kelamin'] = jenisKelamin;
      }

      final response = await http.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? User.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to update profile',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Update profile photo
  Future<ApiResponse<User>> updateProfilePhoto({
    required String profilePhoto, // Base64 string
  }) async {
    final url = Uri.parse('$_baseUrl/profile/photo');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({'profile_photo': profilePhoto}),
      );
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? User.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to update profile photo',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<List<User>>> getAllUsers() async {
    final url = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(
          includeAuth: true,
        ), // Assuming this endpoint requires authentication
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Perbaikan: Tambahkan null check dan pastikan tipe List
        List<User> users = (responseBody['data'] is List)
            ? (responseBody['data'] as List)
                  .map((e) => User.fromJson(e))
                  .toList()
            : []; // Return empty list if data is not a List or is null
        return ApiResponse(
          message: responseBody['message'],
          data: users,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get all users',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- Training Endpoints ---

  Future<ApiResponse<List<Training>>> getTrainings() async {
    final url = Uri.parse('$_baseUrl/trainings');
    try {
      final response = await http.get(url, headers: _getHeaders());

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Perbaikan: Tambahkan null check dan pastikan tipe List
        List<Training> trainings = (responseBody['data'] is List)
            ? (responseBody['data'] as List)
                  .map((e) => Training.fromJson(e))
                  .toList()
            : []; // Return empty list if data is not a List or is null
        return ApiResponse(
          message: responseBody['message'],
          data: trainings,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get trainings',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<Training>> getTrainingDetail(int id) async {
    final url = Uri.parse('$_baseUrl/trainings/$id');
    try {
      final response = await http.get(url, headers: _getHeaders());

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? Training.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get training detail',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- Batch Endpoints ---
  Future<ApiResponse<List<Batch>>> getBatches() async {
    final url = Uri.parse('$_baseUrl/batches');
    try {
      // The Postman collection shows this endpoint requires a token.
      // Adjust if your actual API allows public access.
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Perbaikan: Tambahkan null check dan pastikan tipe List
        List<Batch> batches = (responseBody['data'] is List)
            ? (responseBody['data'] as List)
                  .map((e) => Batch.fromJson(e))
                  .toList()
            : []; // Return empty list if data is not a List or is null
        return ApiResponse(
          message: responseBody['message'],
          data: batches,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get batches',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // Submit Izin Request
  Future<ApiResponse<Absence>> submitIzinRequest({
    required String date, // Date for the izin request
    required String alasanIzin, // Reason for the izin request
  }) async {
    final url = Uri.parse(
      '$_baseUrl/izin',
    ); // Dedicated endpoint for Izin requests
    final body = {'date': date, 'alasan_izin': alasanIzin};

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          message: responseBody['message'],
          // Perbaikan: Tambahkan null check untuk responseBody['data']
          data: responseBody['data'] != null
              ? Absence.fromJson(responseBody['data'])
              : null,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to submit Izin request',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }
}
