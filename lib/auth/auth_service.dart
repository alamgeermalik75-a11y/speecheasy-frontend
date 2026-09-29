import 'package:flutter/foundation.dart';
import '../services/patient_auth_service.dart';

export '../services/patient_auth_service.dart' show PatientUser, AuthApiException;

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  PatientAuthService get _api => PatientAuthService.instance;

  bool get isEmailVerified => _api.isEmailVerified;
  bool get isLoggedIn => _api.isLoggedIn;
  String? get currentUid => _api.currentUid;
  String? get accessToken => _api.accessToken;
  PatientUser? get currentUser => _api.currentUser;

  Future<void> init() => _api.init();

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _api.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    String parentName = '',
    String? childName,
    String? phone,
  }) {
    return _api.register(
      email: email,
      password: password,
      parentName: parentName.isNotEmpty ? parentName : 'Parent',
      childName: childName,
      phone: phone,
    );
  }

  Future<void> sendVerificationEmail([String? email]) async {
    await _api.resendVerification(email);
  }

  Future<bool> verifyEmailToken(String token) {
    return _api.verifyEmail(token: token);
  }

  Future<bool> reloadAndCheckVerified() async {
    await _api.init();
    return _api.isEmailVerified;
  }

  Future<Map<String, dynamic>?> signInWithGoogle() {
    return _api.signInWithGoogle();
  }

  Future<bool> hasChildProfile() {
    return _api.hasChildProfile();
  }

  String parentNameHint() {
    return _api.parentNameHint();
  }

  Future<void> signOut() {
    return _api.logout();
  }

  Future<bool> forgotPassword(String email) {
    return _api.forgotPassword(email);
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _api.resetPassword(token: token, newPassword: newPassword);
  }

  Future<bool> checkHasPassword() {
    return _api.checkHasPassword();
  }

  Future<bool> setPassword(String newPassword) {
    return _api.setPassword(newPassword);
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
