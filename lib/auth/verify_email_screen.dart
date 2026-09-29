import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled1/auth/Signin1.dart';
import 'package:untitled1/auth/auth_service.dart';
import 'package:untitled1/utils/helper.dart';
import 'package:untitled1/views/screens/child_profile.dart';
import 'package:untitled1/views/screens/bottom_navigation/bottom_navigation.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String parentName;
  final String? phone;
  final bool goToChildProfileWhenDone;

  const VerifyEmailScreen({
    super.key,
    required this.parentName,
    this.phone,
    this.goToChildProfileWhenDone = true,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _busy = false;

  String get _email =>
      AuthService.instance.currentUser?.email ?? 'your email';

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await AuthService.instance.sendVerificationEmail();
      if (!mounted) return;
      Field.CustomAlertBox(
        context,
        'A new 6-digit verification code has been sent. Please check your inbox or spam folder.',
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      Field.CustomAlertBox(context, e.message);
    } catch (e) {
      if (!mounted) return;
      Field.CustomAlertBox(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyToken() async {
    final token = _tokenController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (token.isEmpty) {
      Field.CustomAlertBox(context, 'Please enter your 6-digit verification code.');
      return;
    }
    if (token.length != 6) {
      Field.CustomAlertBox(context, 'Verification code must be 6 digits.');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await AuthService.instance.verifyEmailToken(token);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
        _navigateNext();
      }
    } on AuthApiException catch (e) {
      if (!mounted) return;
      Field.CustomAlertBox(context, e.message);
    } catch (e) {
      if (!mounted) return;
      Field.CustomAlertBox(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _iVerified() async {
    setState(() => _busy = true);
    try {
      final ok = await AuthService.instance.reloadAndCheckVerified();
      if (!mounted) return;
      if (!ok) {
        Field.CustomAlertBox(
          context,
          'Email not marked as verified yet. Please enter the token from your email above, or click the email link.',
        );
        return;
      }
      _navigateNext();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _navigateNext() async {
    final hasProfile = await AuthService.instance.hasChildProfile();
    if (!mounted) return;
    if (hasProfile) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavigation()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChildProfile(
            parentName: widget.parentName,
            phone: widget.phone,
          ),
        ),
      );
    }
  }

  Future<void> _backToLogin() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Signin1()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_backspace_sharp, color: Colors.black),
          onPressed: _busy ? null : _backToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your email',
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit verification code to\n$_email\n\n'
                'Enter the 6-digit code below, or click the verification link in your email:',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _tokenController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                maxLength: 6,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: const Color(0xff1B5E20),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: '6-Digit Verification Code (OTP)',
                  hintText: '123456',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 4,
                    color: Colors.black26,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Button(
                t1: _busy ? 'Verifying…' : 'Verify Code',
                color: const Color(0xff38796D),
                ontap: () {
                  if (!_busy) _verifyToken();
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _iVerified,
                  child: Text(
                    'I tapped the link in my email',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _resend,
                  child: Text(
                    'Resend email',
                    style: GoogleFonts.poppins(
                      color: const Color(0xff38796D),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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
