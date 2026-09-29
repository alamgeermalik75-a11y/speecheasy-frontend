import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/helper.dart';
import 'Signin1.dart';
import 'auth_service.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Field.CustomAlertBox(context, 'Please enter your email address.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('6-digit reset code sent! Please check your email.'),
          backgroundColor: Color(0xff38796D),
        ),
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

  Future<void> _submitNewPassword() async {
    final otp = otpController.text.trim();
    final newPwd = newPasswordController.text;
    final confirmPwd = confirmPasswordController.text;

    if (otp.isEmpty || otp.length < 6) {
      Field.CustomAlertBox(context, 'Please enter the 6-digit code from your email.');
      return;
    }
    if (newPwd.length < 8) {
      Field.CustomAlertBox(context, 'Password must be at least 8 characters long.');
      return;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(newPwd) || !RegExp(r'\d').hasMatch(newPwd)) {
      Field.CustomAlertBox(context, 'Password must contain at least one letter and one number.');
      return;
    }
    if (newPwd != confirmPwd) {
      Field.CustomAlertBox(context, 'Passwords do not match.');
      return;
    }

    setState(() => _busy = true);
    try {
      final ok = await AuthService.instance.resetPassword(
        token: otp,
        newPassword: newPwd,
      );
      if (!mounted) return;
      if (ok) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Password Reset Successful',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Your password has been updated. You can now log into your SpeechEasy account with your new password.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Signin1()),
                    (_) => false,
                  );
                },
                child: Text(
                  'Go to Login',
                  style: GoogleFonts.poppins(
                    color: const Color(0xff38796D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () {
                  if (_codeSent) {
                    setState(() => _codeSent = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFBAB49B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_backspace_sharp,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            automaticallyImplyLeading: false,
          ),
        ),
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFBF9F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                _codeSent ? 'Set New Password' : 'Reset your Password',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to ${emailController.text.trim()} and your new password below:'
                    : "Enter your email and we'll send you a 6-digit OTP code to reset your password.",
                style: GoogleFonts.poppins(color: Colors.black54, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              if (!_codeSent) ...[
                Field(
                  Obscure: false,
                  inputtype: TextInputType.emailAddress,
                  controller: emailController,
                  t1: 'Email Address',
                  t2: 'hello@gmail.com',
                ),
                const SizedBox(height: 25),
                Button(
                  t1: _busy ? 'Sending Code…' : 'Send Reset Code',
                  color: const Color(0xff38796D),
                  ontap: () {
                    if (!_busy) _sendResetCode();
                  },
                ),
              ] else ...[
                Text(
                  '6-Digit Verification Code',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
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
                    hintText: '123456',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 4,
                      color: Colors.black26,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Password',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    hintText: 'Minimum 8 characters (letters & numbers)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black45,
                      ),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirm New Password',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your new password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black45,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Button(
                  t1: _busy ? 'Resetting…' : 'Reset Password',
                  color: const Color(0xff38796D),
                  ontap: () {
                    if (!_busy) _submitNewPassword();
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _sendResetCode,
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.poppins(
                        color: const Color(0xff38796D),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remember your password?',
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Signin1()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: GoogleFonts.poppins(
                        color: const Color(0xff38796D),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
