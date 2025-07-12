// lib/models/app_models.dart

// Helper function to safely parse int from dynamic (could be int or string)
int? _parseIntFromDynamic(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

// --- API Response Models ---
class ApiResponse<T> {
  final String message; // This is non-nullable
  final T? data;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiResponse({required this.message, this.data, this.errors, this.statusCode});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    int? parsedStatusCode;
    if (json.containsKey('status_code')) {
      parsedStatusCode = _parseIntFromDynamic(json['status_code']);
    }

    // Safely get message, provide a default if it's null from API
    final String parsedMessage =
        json['message'] as String? ?? 'An unexpected error occurred.';

    return ApiResponse(
      message: parsedMessage, // Use the safely parsed message
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] as Map<String, dynamic>?,
      statusCode: parsedStatusCode,
    );
  }

  factory ApiResponse.fromError(
    String message, {
    int? statusCode,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse(
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

// --- Authentication Models ---
class AuthResponse {
  final String message;
  final AuthData? data;

  AuthResponse({required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message:
          json['message'] as String? ??
          'Authentication response message missing.', // Added null-check
      data: json['data'] != null
          ? AuthData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AuthData {
  final String token;
  final User user;

  AuthData({required this.token, required this.user});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

// --- User Profile Models ---
class User {
  final int id;
  final String name;
  final String email;
  final String? batch_ke; // Added new field
  final String? training_title; // Added new field
  final String? jenis_kelamin; // Added new field
  final String? profile_photo; // Added new field
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt; // Made nullable
  final DateTime? updatedAt; // Made nullable
  final int? batchId;
  final int? trainingId;
  final Batch? batch; // Nested Batch object
  final Training? training; // Nested Training object

  User({
    required this.id,
    required this.name,
    required this.email,
    this.batch_ke, // Added to constructor
    this.training_title, // Added to constructor
    this.jenis_kelamin, // Added to constructor
    this.profile_photo, // Added to constructor
    this.emailVerifiedAt,
    this.createdAt, // Removed required
    this.updatedAt, // Removed required
    this.batchId,
    this.trainingId,
    this.batch,
    this.training,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:
          _parseIntFromDynamic(json['id']) ??
          0, // Use helper, provide default for required id
      name:
          json['name'] as String? ??
          'Unknown Name', // Added null-aware cast and fallback
      email:
          json['email'] as String? ??
          'unknown@example.com', // Added null-aware cast and fallback
      batch_ke: json['batch_ke'] as String?, // Parse new field
      training_title: json['training_title'] as String?, // Parse new field
      jenis_kelamin: json['jenis_kelamin'] as String?, // Parse new field
      profile_photo: json['profile_photo'] as String?, // Parse new field
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      createdAt:
          json['created_at'] !=
              null // Added null-check before parsing
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt:
          json['updated_at'] !=
              null // Added null-check before parsing
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      batchId: _parseIntFromDynamic(json['batch_id']), // Use helper for batchId
      trainingId: _parseIntFromDynamic(
        json['training_id'],
      ), // Use helper for trainingId
      batch: json['batch'] != null
          ? Batch.fromJson(json['batch'] as Map<String, dynamic>)
          : null,
      training: json['training'] != null
          ? Training.fromJson(json['training'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'batch_ke': batch_ke, // Added to toJson
      'training_title': training_title, // Added to toJson
      'jenis_kelamin': jenis_kelamin, // Added to toJson
      'profile_photo': profile_photo, // Added to toJson
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'batch_id': batchId,
      'training_id': trainingId,
      'batch': batch?.toJson(),
      'training': training?.toJson(),
    };
  }
}

// --- Attendance Models ---
class Absence {
  final int id;
  final int userId;
  final DateTime? checkIn; // Made nullable
  final String? checkInLocation;
  final String? checkInAddress; // Made nullable
  final DateTime? checkOut;
  final String? checkOutLocation;
  final String? checkOutAddress;
  final String? status; // Made nullable
  final String? alasanIzin;
  final DateTime? createdAt; // Made nullable
  final DateTime? updatedAt; // Made nullable
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final DateTime? attendanceDate;

  Absence({
    required this.id,
    required this.userId,
    this.checkIn, // Removed required
    this.checkInLocation,
    this.checkInAddress, // Removed required
    this.checkOut,
    this.checkOutLocation,
    this.checkOutAddress,
    this.status, // Removed required
    this.alasanIzin,
    this.createdAt, // Removed required
    this.updatedAt, // Removed required
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.attendanceDate,
  });

  factory Absence.fromJson(Map<String, dynamic> json) {
    final String? attendanceDateStr = json['attendance_date'] as String?;
    final String? checkInTimeStr = json['check_in_time'] as String?;
    final String? checkOutTimeStr = json['check_out_time'] as String?;

    DateTime? parsedCheckIn;
    if (attendanceDateStr != null && checkInTimeStr != null) {
      try {
        parsedCheckIn = DateTime.parse('$attendanceDateStr $checkInTimeStr');
      } catch (e) {
        print('Error parsing checkIn in Absence: $e');
      }
    }

    DateTime? parsedCheckOut;
    if (attendanceDateStr != null && checkOutTimeStr != null) {
      try {
        parsedCheckOut = DateTime.parse('$attendanceDateStr $checkOutTimeStr');
      } catch (e) {
        print('Error parsing checkOut in Absence: $e');
      }
    }

    return Absence(
      id: _parseIntFromDynamic(json['id']) ?? 0, // Use helper
      userId: _parseIntFromDynamic(json['user_id']) ?? 0, // Use helper
      checkIn: parsedCheckIn,
      checkInLocation: json['check_in_location'] as String?,
      checkInAddress:
          json['check_in_address'] as String? ??
          'N/A', // Added null-aware cast and fallback
      checkOut: parsedCheckOut,
      checkOutLocation: json['check_out_location'] as String?,
      checkOutAddress: json['check_out_address'] as String?,
      status:
          json['status'] as String? ??
          'N/A', // Added null-aware cast and fallback
      alasanIzin: json['alasan_izin'] as String?,
      createdAt:
          json['created_at'] !=
              null // Added null-check before parsing
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt:
          json['updated_at'] !=
              null // Added null-check before parsing
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      checkInLat: (json['check_in_lat'] as num?)?.toDouble(),
      checkInLng: (json['check_in_lng'] as num?)?.toDouble(),
      checkOutLat: (json['check_out_lat'] as num?)?.toDouble(),
      checkOutLng: (json['check_out_lng'] as num?)?.toDouble(),
      attendanceDate: attendanceDateStr != null
          ? DateTime.parse(attendanceDateStr)
          : null, // Parse new field as DateTime
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in': checkIn?.toIso8601String(),
      'check_in_location': checkInLocation,
      'check_in_address': checkInAddress,
      'check_out': checkOut?.toIso8601String(),
      'check_out_location': checkOutLocation,
      'check_out_address': checkOutAddress,
      'status': status,
      'alasan_izin': alasanIzin,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
    };
  }
}

class AbsenceToday {
  final DateTime? tanggal; // Made nullable
  final DateTime? jamMasuk; // Made nullable
  final DateTime? jamKeluar;
  final String? alamatMasuk; // Made nullable
  final String? alamatKeluar;
  final String? status; // Made nullable
  final String? alasanIzin;
  final DateTime? attendanceDate;

  AbsenceToday({
    this.tanggal, // Removed required
    this.jamMasuk, // Removed required
    this.jamKeluar,
    this.alamatMasuk, // Removed required
    this.alamatKeluar,
    this.status, // Removed required
    this.alasanIzin,
    this.attendanceDate,
  });

  factory AbsenceToday.fromJson(Map<String, dynamic> json) {
    final String? attendanceDateStr = json['attendance_date'] as String?;
    final String? checkInTimeStr = json['check_in_time'] as String?;
    final String? checkOutTimeStr = json['check_out_time'] as String?;

    DateTime? parsedJamMasuk;
    if (attendanceDateStr != null && checkInTimeStr != null) {
      try {
        parsedJamMasuk = DateTime.parse('$attendanceDateStr $checkInTimeStr');
      } catch (e) {
        print('Error parsing jamMasuk: $e');
      }
    }

    DateTime? parsedJamKeluar;
    if (attendanceDateStr != null && checkOutTimeStr != null) {
      try {
        parsedJamKeluar = DateTime.parse('$attendanceDateStr $checkOutTimeStr');
      } catch (e) {
        print('Error parsing jamKeluar: $e');
      }
    }

    return AbsenceToday(
      tanggal: attendanceDateStr != null
          ? DateTime.parse(attendanceDateStr)
          : null, // Parse as DateTime
      jamMasuk: parsedJamMasuk,
      jamKeluar: parsedJamKeluar,
      alamatMasuk:
          json['check_in_address'] as String? ??
          'N/A', // Changed from 'alamat_masuk' to 'check_in_address'
      alamatKeluar:
          json['check_out_address']
              as String?, // Changed from 'alamat_keluar' to 'check_out_address'
      status:
          json['status'] as String? ??
          'N/A', // Added null-aware cast and fallback
      alasanIzin: json['alasan_izin'] as String?,
      attendanceDate: attendanceDateStr != null
          ? DateTime.parse(attendanceDateStr)
          : null,
    );
  }
}

class AbsenceStats {
  final int totalAbsen;
  final int totalMasuk;
  final int totalIzin;
  final bool sudahAbsenHariIni;

  AbsenceStats({
    required this.totalAbsen,
    required this.totalMasuk,
    required this.totalIzin,
    required this.sudahAbsenHariIni,
  });

  factory AbsenceStats.fromJson(Map<String, dynamic> json) {
    return AbsenceStats(
      totalAbsen: _parseIntFromDynamic(json['total_absen']) ?? 0, // Use helper
      totalMasuk: _parseIntFromDynamic(json['total_masuk']) ?? 0, // Use helper
      totalIzin: _parseIntFromDynamic(json['total_izin']) ?? 0, // Use helper
      sudahAbsenHariIni:
          json['sudah_absen_hari_ini'] as bool? ??
          false, // Added null-check and fallback
    );
  }
}

// --- Batch and Training Models ---
class Batch {
  final int id;
  final String batch_ke; // Corrected to match API response
  final String? startDate; // Made nullable
  final String? endDate; // Made nullable
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Training>? trainings; // Nested trainings from API response

  Batch({
    required this.id,
    required this.batch_ke,
    this.startDate, // Removed required
    this.endDate, // Removed required
    this.createdAt,
    this.updatedAt,
    this.trainings,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: _parseIntFromDynamic(json['id']) ?? 0, // Use helper
      batch_ke:
          json['batch_ke'] as String? ??
          'N/A', // Added null-aware cast and fallback
      startDate: json['start_date'] as String?, // Added null-aware cast
      endDate: json['end_date'] as String?, // Added null-aware cast
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      trainings: (json['trainings'] as List<dynamic>?)
          ?.map((e) => Training.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_ke': batch_ke,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'trainings': trainings?.map((e) => e.toJson()).toList(),
    };
  }
}

class Training {
  final int id;
  final String title;
  final String? description;
  final int? participantCount;
  final String? standard;
  final String? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic>?
  units; // Assuming units and activities can be dynamic lists
  final List<dynamic>? activities;

  Training({
    required this.id,
    required this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.units,
    this.activities,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: _parseIntFromDynamic(json['id']) ?? 0, // Use helper
      title:
          json['title'] as String? ??
          'N/A', // Added null-aware cast and fallback
      description: json['description'] as String?,
      participantCount: _parseIntFromDynamic(
        json['participant_count'],
      ), // Use helper
      standard: json['standard'] as String?,
      duration: json['duration'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      units: json['units'] as List<dynamic>?,
      activities: json['activities'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'participant_count': participantCount,
      'standard': standard,
      'duration': duration,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'units': units,
      'activities': activities,
    };
  }
}
