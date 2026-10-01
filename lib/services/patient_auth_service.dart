import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show VoidCallback;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../auth/web_auth_bridge.dart';
import 'core_backend_service.dart';

class AuthApiException implements Exception {
  final String code;
  final String message;

  AuthApiException(this.code, this.message);

  @override
  String toString() => message;
}

class PatientUser {
  final String uid;
  final String email;
  final String role;
  final bool isVerified;
  final String? parentName;
  final bool hasPassword;

  PatientUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.isVerified,
    this.parentName,
    this.hasPassword = false,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'role': role,
        'isVerified': isVerified,
        'parentName': parentName,
        'hasPassword': hasPassword,
      };

  factory PatientUser.fromJson(Map<String, dynamic> json) => PatientUser(
        uid: json['uid'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'patient',
        isVerified: json['isVerified'] as bool? ?? false,
        parentName: json['parentName'] as String?,
        hasPassword: json['hasPassword'] as bool? ?? false,
      );
}

class PatientAuthService {
  PatientAuthService._();
  static final PatientAuthService instance = PatientAuthService._();

  static const String _tokenKey = 'speecheasy_access_token';
  static const String _refreshKey = 'speecheasy_refresh_token';
  static const String _userKey = 'speecheasy_user_data';

  String? _accessToken;
  String? _refreshToken;
  PatientUser? _currentUser;
  bool _initialized = false;
  bool _googleReady = false;

  static const String _defaultLiveAuthUrl =
      'https://speecheasy-auth-service-production.up.railway.app/api/v1';

  String get _baseUrl {
    final configured = AuthApiConfig.baseUrl.trim();
    if (configured.isEmpty ||
        configured.contains('localhost') ||
        configured.contains('127.0.0.1')) {
      return _defaultLiveAuthUrl;
    }
    return configured;
  }

  bool get isLoggedIn => _accessToken != null && _currentUser != null;
  bool get isEmailVerified => _currentUser?.isVerified ?? false;
  String? get currentUid => _currentUser?.uid;
  String? get currentEmail => _currentUser?.email;
  String? get accessToken => _accessToken;
  PatientUser? get currentUser => _currentUser;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshKey);
      final rawUser = prefs.getString(_userKey);
      if (rawUser != null) {
        _currentUser = PatientUser.fromJson(jsonDecode(rawUser));
      }
    } catch (e) {
      debugPrint('Error initializing PatientAuthService: $e');
    } finally {
      _initialized = true;
    }
    _subscribeToGoogleAuthEvents();
  }

  VoidCallback? onGoogleSignInSuccess;
  void Function(String error)? onGoogleSignInError;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleReady) return;
    _googleReady = true;
    _subscribeToGoogleAuthEvents();
    try {
      if (kIsWeb) {
        await GoogleSignIn.instance.initialize(
          clientId: GoogleAuthConfig.webClientId,
        );
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: GoogleAuthConfig.webClientId,
        );
      }
    } catch (e) {
      debugPrint('GoogleSignIn initialize: $e');
    }
  }

  /// Public method for pre-initializing Google Sign In (used in initState)
  Future<void> ensureGoogleInitializedPublic() => _ensureGoogleInitialized();

  Future<Map<String, dynamic>>? _inFlightBackendAuth;
  bool _subscribed = false;

  void _subscribeToGoogleAuthEvents() {
    if (!kIsWeb) return;
    if (_subscribed) return;
    _subscribed = true;

    // 1. Direct Web Hook: listens to CustomEvent from window (most reliable on web)
    listenForWebGoogleToken((idToken) async {
      debugPrint('[PatientAuthService] Captured Google token via web event bridge! Authenticating...');
      try {
        await _authenticateWithBackend(idToken, null);
        onGoogleSignInSuccess?.call();
      } catch (e) {
        debugPrint('Error handling Google token via web bridge: $e');
        final msg = (e is AuthApiException) ? e.message : e.toString();
        onGoogleSignInError?.call(msg);
      }
    });

    // 2. Plugin stream fallback
    try {
      GoogleSignIn.instance.authenticationEvents.listen((event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          try {
            final account = event.user;
            final auth = account.authentication;
            final idToken = auth.idToken;
            if (idToken != null && idToken.isNotEmpty) {
              await _authenticateWithBackend(idToken, account.displayName);
              onGoogleSignInSuccess?.call();
            }
          } catch (e) {
            debugPrint('Error handling GoogleSignIn event: $e');
            final msg = (e is AuthApiException) ? e.message : e.toString();
            onGoogleSignInError?.call(msg);
          }
        }
      });
    } catch (e) {
      debugPrint('Error listening to GoogleSignIn.instance.authenticationEvents: $e');
    }
  }

  Future<Map<String, dynamic>> _authenticateWithBackend(
    String idToken,
    String? displayName,
  ) async {
    if (_inFlightBackendAuth != null) {
      return _inFlightBackendAuth!;
    }
    final future = _performAuthenticateWithBackend(idToken, displayName);
    _inFlightBackendAuth = future;
    try {
      return await future;
    } finally {
      _inFlightBackendAuth = null;
    }
  }

  Future<Map<String, dynamic>> _performAuthenticateWithBackend(
    String idToken,
    String? displayName,
  ) async {
    final url = Uri.parse('$_baseUrl/auth/google');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final isVerified = data['is_verified'] == true;
      final verificationRequired = data['verification_required'] == true;

      if (!isVerified || verificationRequired) {
        final userMap = data['user'] as Map<String, dynamic>?;
        _accessToken = null;
        _refreshToken = null;
        _currentUser = PatientUser(
          uid: userMap?['id'] ?? '',
          email: data['email'] ?? userMap?['email'] ?? '',
          role: 'patient',
          isVerified: false,
          parentName: displayName,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await prefs.remove(_refreshKey);
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        return data;
      }

      final userMap = data['user'] as Map<String, dynamic>;
      await _saveSession(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        userMap: userMap,
        parentNameHint: displayName,
      );
      return data;
    }

    _handleErrorResponse(res);
  }

  Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userMap,
    String? parentNameHint,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _currentUser = PatientUser(
      uid: userMap['id'] ?? userMap['uid'] ?? '',
      email: userMap['email'] ?? '',
      role: userMap['role'] ?? 'patient',
      isVerified: userMap['is_verified'] ?? userMap['isVerified'] ?? true,
      parentName: parentNameHint ?? _currentUser?.parentName,
      hasPassword: userMap['has_password'] ?? userMap['hasPassword'] ?? false,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _accessToken!);
    await prefs.setString(_refreshKey, _refreshToken!);
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }

  Never _handleErrorResponse(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body.containsKey('error')) {
        final err = body['error'];
        final code = err['code'] ?? 'AUTH_ERROR';
        final msg = err['message'] ?? 'An error occurred';
        throw AuthApiException(code.toString(), msg.toString());
      }
    } catch (e) {
      if (e is AuthApiException) rethrow;
    }
    throw AuthApiException(
      'HTTP_${res.statusCode}',
      'Authentication request failed (${res.statusCode}): ${res.body}',
    );
  }

  /// Register patient with server-controlled role='patient'
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String parentName,
    String? childName,
    String? phone,
  }) async {
    await init();
    final url = Uri.parse('$_baseUrl/auth/register/patient');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'parent_name': parentName.trim(),
        if (childName != null && childName.trim().isNotEmpty)
          'child_name': childName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      }),
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      // Save pending user
      _currentUser = PatientUser(
        uid: data['user_id'] ?? '',
        email: data['email'] ?? email.trim(),
        role: 'patient',
        isVerified: false,
        parentName: parentName.trim(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      return data;
    }

    _handleErrorResponse(res);
  }

  /// Login with email & password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await init();
    final url = Uri.parse('$_baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'client_type': 'patient',
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      await _saveSession(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        userMap: userMap,
      );
      return data;
    }

    _handleErrorResponse(res);
  }

  /// Login or register via Google ID token (supports Web and Mobile)
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    await init();
    await _ensureGoogleInitialized();

    try {
      if (kIsWeb) {
        // On web, attempt lightweight sign-in (One Tap / FedCM)
        await GoogleSignIn.instance.attemptLightweightAuthentication();
        return null;
      }

      // On Android / iOS, trigger interactive authentication
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthApiException(
          'MISSING_GOOGLE_TOKEN',
          'Google did not return an ID token.',
        );
      }

      return await _authenticateWithBackend(idToken, googleUser.displayName);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException('GOOGLE_SIGN_IN_ERROR', e.toString());
    }
  }

  /// Verify email with single-use token
  Future<bool> verifyEmail({required String token}) async {
    await init();
    final cleanToken = token.replaceAll(RegExp(r'[\s\-]'), '').trim();
    final url = Uri.parse('$_baseUrl/auth/verify-email');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': cleanToken}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['access_token'] != null && data['refresh_token'] != null) {
        final userMap = data['user'] as Map<String, dynamic>? ?? {
          'id': _currentUser?.uid ?? '',
          'email': _currentUser?.email ?? '',
          'role': 'patient',
          'is_verified': true,
        };
        await _saveSession(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userMap: userMap,
          parentNameHint: _currentUser?.parentName,
        );
      } else if (_currentUser != null) {
        _currentUser = PatientUser(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          role: _currentUser!.role,
          isVerified: true,
          parentName: _currentUser!.parentName,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }
      return true;
    }

    _handleErrorResponse(res);
  }

  /// Resend verification email
  Future<bool> resendVerification([String? email]) async {
    await init();
    final targetEmail = email?.trim() ?? _currentUser?.email;
    if (targetEmail == null || targetEmail.isEmpty) {
      throw AuthApiException('EMAIL_REQUIRED', 'Please provide an email address.');
    }

    final url = Uri.parse('$_baseUrl/auth/resend-verification');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': targetEmail}),
    );

    if (res.statusCode == 200) {
      return true;
    }

    _handleErrorResponse(res);
  }

  /// Request password reset email
  Future<bool> forgotPassword(String email) async {
    await init();
    final url = Uri.parse('$_baseUrl/auth/forgot-password');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    if (res.statusCode == 200) {
      return true;
    }

    _handleErrorResponse(res);
  }

  /// Reset password using token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await init();
    final url = Uri.parse('$_baseUrl/auth/reset-password');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token.trim(),
        'new_password': newPassword,
      }),
    );

    if (res.statusCode == 200) {
      return true;
    }

    _handleErrorResponse(res);
  }

  /// Rotates refresh token and issues new access token
  Future<bool> refreshToken() async {
    await init();
    if (_refreshToken == null) return false;

    try {
      final url = Uri.parse('$_baseUrl/auth/refresh');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final userMap = data['user'] as Map<String, dynamic>;
        await _saveSession(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userMap: userMap,
          parentNameHint: _currentUser?.parentName,
        );
        return true;
      }
    } catch (_) {}

    await _clearSession();
    return false;
  }

  /// Logout and revoke refresh session
  Future<void> logout() async {
    await init();
    try {
      final url = Uri.parse('$_baseUrl/auth/logout');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }
      await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          if (_refreshToken != null) 'refresh_token': _refreshToken,
        }),
      );
    } catch (e) {
      debugPrint('Logout API note: $e');
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _clearSession();
  }

  /// Check if child profile exists in backend and is configured
  Future<bool> hasChildProfile() async {
    await init();
    if (!isLoggedIn) return false;
    try {
      final profile = await CoreBackendService().getMyProfile();
      if (profile == null || profile.isEmpty) return false;
      final child = profile['child_name']?.toString().trim();
      return child != null &&
          child.isNotEmpty &&
          child.toLowerCase() != 'child' &&
          child.toLowerCase() != 'my child';
    } catch (_) {
      return false;
    }
  }

  String parentNameHint() {
    if (_currentUser?.parentName?.isNotEmpty == true) {
      return _currentUser!.parentName!;
    }
    if (_currentUser?.email.isNotEmpty == true) {
      return _currentUser!.email.split('@').first;
    }
    return '';
  }

  /// Checks whether current user has a password set on the account
  Future<bool> checkHasPassword() async {
    await init();
    if (_accessToken == null) return false;
    try {
      final url = Uri.parse('$_baseUrl/auth/me');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final hasPwd = data['has_password'] == true;
        if (_currentUser != null) {
          _currentUser = PatientUser(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            role: _currentUser!.role,
            isVerified: _currentUser!.isVerified,
            parentName: _currentUser!.parentName,
            hasPassword: hasPwd,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        }
        return hasPwd;
      }
    } catch (_) {}
    return _currentUser?.hasPassword ?? false;
  }

  /// Sets password for account that currently does not have a password (e.g. Google user)
  Future<bool> setPassword(String newPassword) async {
    await init();
    if (_accessToken == null) {
      throw AuthApiException('NOT_AUTHENTICATED', 'Please log in first.');
    }
    final url = Uri.parse('$_baseUrl/auth/set-password');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({'new_password': newPassword.trim()}),
    );

    if (res.statusCode == 200) {
      if (_currentUser != null) {
        _currentUser = PatientUser(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          role: _currentUser!.role,
          isVerified: _currentUser!.isVerified,
          parentName: _currentUser!.parentName,
          hasPassword: true,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }
      return true;
    }

    _handleErrorResponse(res);
  }

  /// Changes password for account with an existing password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await init();
    if (_accessToken == null) {
      throw AuthApiException('NOT_AUTHENTICATED', 'Please log in first.');
    }
    final url = Uri.parse('$_baseUrl/auth/change-password');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword.trim(),
      }),
    );

    if (res.statusCode == 200) {
      return true;
    }

    _handleErrorResponse(res);
  }
}
