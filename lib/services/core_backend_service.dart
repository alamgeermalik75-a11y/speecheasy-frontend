import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'patient_auth_service.dart';

class CoreBackendService {
  static final CoreBackendService _instance = CoreBackendService._internal();
  factory CoreBackendService() => _instance;
  CoreBackendService._internal();

  static const String _defaultLiveCoreUrl =
      'https://speecheasy-speech-backend-production.up.railway.app/api/v1';

  String get _baseUrl {
    final configured = CoreBackendConfig.baseUrl.trim();
    if (configured.isEmpty ||
        configured.contains('localhost') ||
        configured.contains('127.0.0.1')) {
      return _defaultLiveCoreUrl;
    }
    return configured;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    await PatientAuthService.instance.init();
    final patientToken = PatientAuthService.instance.accessToken;
    final patientUid = PatientAuthService.instance.currentUid;

    if (patientToken != null && patientToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $patientToken';
    }
    if (patientUid != null && patientUid.isNotEmpty) {
      headers['X-Patient-UID'] = patientUid;
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdToken();
          if (token != null && token.isNotEmpty && headers['Authorization'] == null) {
            headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        headers['X-Patient-UID'] = user.uid;
      }
    }
    return headers;
  }

  // --- Profiles & Focus Sound ---
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/profiles/me'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data;
      }
      if (res.statusCode == 401) {
        final refreshed = await PatientAuthService.instance.refreshToken();
        if (refreshed) {
          final newHeaders = await _getHeaders();
          final retryRes = await http.get(Uri.parse('$_baseUrl/profiles/me'), headers: newHeaders);
          if (retryRes.statusCode == 200) {
            return jsonDecode(retryRes.body) as Map<String, dynamic>;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveProfile({
    required String parentName,
    required String childName,
    int? age,
    String? phone,
    String? sound,
    String? alphabetName,
  }) async {
    try {
      final payload = jsonEncode({
        'parent_name': parentName,
        'child_name': childName,
        'age': age,
        'phone': phone,
        'sound': sound,
        'alphabet_name': alphabetName,
      });

      var headers = await _getHeaders();
      var res = await http.post(
        Uri.parse('$_baseUrl/profiles'),
        headers: headers,
        body: payload,
      );

      if (res.statusCode == 401) {
        final refreshed = await PatientAuthService.instance.refreshToken();
        if (refreshed) {
          headers = await _getHeaders();
          res = await http.post(
            Uri.parse('$_baseUrl/profiles'),
            headers: headers,
            body: payload,
          );
        }
      }

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMyProfile() async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/profiles/me'),
        headers: await _getHeaders(),
      );
      return res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // --- Daily Tips ---
  Future<List<Map<String, dynamic>>> getDailyTips() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/daily-tips'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // --- Therapists & Requests ---
  Future<List<Map<String, dynamic>>> getTherapists() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/therapists'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTherapistByCode(String code) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/therapists/by-code/$code'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> requestTherapist(String doctorId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/therapists/request'),
        headers: await _getHeaders(),
        body: jsonEncode({'doctor_id': doctorId}),
      );
      if (res.statusCode == 201) {
        return {'success': true, 'message': "Registration request sent! You'll be notified once they accept."};
      }
      final body = jsonDecode(res.body);
      final detail = body['detail'] ?? 'Failed to send request.';
      return {'success': false, 'message': detail};
    } catch (e) {
      return {'success': false, 'message': 'Connection error. Please try again.'};
    }
  }

  Future<Map<String, dynamic>?> getMyDoctorStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/therapists/my-status'),
        headers: await _getHeaders(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> unregisterDoctor() async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/therapists/my-doctor'),
        headers: await _getHeaders(),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }


  // --- Slots & Appointments ---
  Future<Map<String, dynamic>> getDoctorSlotsWithDetails(String doctorId, String dateYmd) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/therapists/$doctorId/slots?date=$dateYmd'),
        headers: await _getHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawSlots = (data['slots'] as List? ?? []).map((e) => e.toString()).toList();
        final rawAll = (data['all_slots'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return {
          'slots': rawSlots,
          'all_slots': rawAll,
        };
      }
      return {'slots': <String>[], 'all_slots': <Map<String, dynamic>>[]};
    } catch (_) {
      return {'slots': <String>[], 'all_slots': <Map<String, dynamic>>[]};
    }
  }

  Future<List<String>> getDoctorSlots(String doctorId, String dateYmd) async {
    final res = await getDoctorSlotsWithDetails(doctorId, dateYmd);
    return res['slots'] as List<String>;
  }

  Future<Map<String, dynamic>> bookAppointment({
    required String doctorId,
    required String appointmentDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/appointments'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'doctor_id': doctorId,
          'appointment_date': appointmentDate,
          'start_time': startTime,
          'end_time': endTime,
        }),
      );
      if (res.statusCode == 201) {
        return {'success': true, 'message': 'Appointment requested! Pending therapist confirmation.'};
      }
      final body = jsonDecode(res.body);
      final detail = body['detail'] ?? 'Failed to book appointment.';
      return {'success': false, 'message': detail, 'statusCode': res.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Connection error. Please try again.'};
    }
  }

  Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/appointments/$appointmentId/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'status': newStatus}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- Ratings ---
  Future<int?> getMyRating(String doctorId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/ratings/$doctorId/my-rating'),
        headers: await _getHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['rating'] as int?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitRating(String doctorId, int stars) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/ratings'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'doctor_id': doctorId,
          'rating': stars,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- Practice Attempts ---
  Future<Map<String, dynamic>?> recordAttempt({
    required String itemId,
    required String alphabetName,
    required String levelKey,
    required int score,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/attempts'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'item_id': itemId,
          'alphabet_name': alphabetName,
          'level_key': levelKey,
          'score': score,
        }),
      );
      if (res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAttemptHistory({String? alphabetName}) async {
    try {
      var url = '$_baseUrl/attempts/history';
      if (alphabetName != null) {
        url += '?alphabet_name=$alphabetName';
      }
      final res = await http.get(Uri.parse(url), headers: await _getHeaders());
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // --- Notifications ---
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/notifications'), headers: await _getHeaders());
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: await _getHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['count'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> markNotificationsRead() async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/notifications/mark-read'),
        headers: await _getHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearNotifications() async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/notifications'),
        headers: await _getHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- AI Chatbot ---
  Future<String> chat(String message) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: await _getHeaders(),
        body: jsonEncode({'message': message}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['reply'] as String? ?? 'No response received.';
      }
      return 'Sorry, the assistant is currently unavailable.';
    } catch (e) {
      return 'Network error connecting to assistant.';
    }
  }
}
