import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled1/auth/auth_service.dart';
import 'package:untitled1/auth/verify_email_screen.dart';
import '../utils/helper.dart';
import '../services/patient_auth_service.dart';
import 'google_button.dart';
import '../views/screens/child_profile.dart';
import '../views/screens/bottom_navigation/bottom_navigation.dart';
import 'Signin1.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    PatientAuthService.instance.onGoogleSignInSuccess = null;
    PatientAuthService.instance.onGoogleSignInError = null;
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    PatientAuthService.instance.onGoogleSignInSuccess = () async {
      if (!mounted) return;
      if (!AuthService.instance.isEmailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              parentName: AuthService.instance.parentNameHint(),
              goToChildProfileWhenDone: true,
            ),
          ),
        );
        return;
      }
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
              parentName: AuthService.instance.parentNameHint(),
            ),
          ),
        );
      }
    };
    PatientAuthService.instance.onGoogleSignInError = (errorMsg) {
      if (mounted) {
        Field.CustomAlertBox(context, errorMsg);
      }
    };
    // Pre-initialize Google Sign In on web so the GIS button is ready to render
    PatientAuthService.instance.init().then((_) {
      PatientAuthService.instance.ensureGoogleInitializedPublic();
    });
  }

  Future<void> signup(
    String email,
    String password,
    String confirmPassword,
    String username,
    String phone,
  ) async {
    if (email.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        username.trim().isEmpty) {
      Field.CustomAlertBox(context, 'Enter required fields');
      return;
    }
    if (password != confirmPassword) {
      Field.CustomAlertBox(context, 'Passwords do not match');
      return;
    }
    if (password.length < 8) {
      Field.CustomAlertBox(context, 'Password must be at least 8 characters with letters and numbers');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        parentName: username.trim(),
        phone: phone.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            parentName: username.trim(),
            phone: phone.trim(),
          ),
        ),
      );
    } on AuthApiException catch (ex) {
      if (!mounted) return;
      Field.CustomAlertBox(context, ex.message);
    } catch (e) {
      if (!mounted) return;
      Field.CustomAlertBox(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> signupWithGoogle() async {
    setState(() => _busy = true);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result != null) {
        if (!AuthService.instance.isEmailVerified) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                parentName: AuthService.instance.parentNameHint(),
                goToChildProfileWhenDone: true,
              ),
            ),
          );
          return;
        }
        // Mobile: navigate immediately after sign-in
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
                parentName: AuthService.instance.parentNameHint(),
              ),
            ),
          );
        }
      }
      // Web: navigation happens via onGoogleSignInSuccess callback
    } on AuthApiException catch (ex) {
      if (!mounted) return;
      Field.CustomAlertBox(context, ex.message);
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
        preferredSize:  Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: (){
                  Navigator.pop(context);
                },
                child: Container(
                  child: Icon(Icons.keyboard_backspace_sharp, color: Colors.black,),
                  decoration: BoxDecoration(
                      color: Color(0xFFBAB49B).withOpacity(0.2),
                      shape: BoxShape.circle
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
      backgroundColor: Color(0xFFFBF9F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, color: Colors.black, size: 35),
                SizedBox(height: 10),
                Text(
                  'Create your account',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Takes less than a minute.',
                  style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
                ),
                SizedBox(height: 20),
                Field(
                  Obscure: false,
                  inputtype: TextInputType.text,
                  t1: 'Parent Name',
                  t2: 'e.g. Ayesha ',
                  controller: usernameController,
                ),
                SizedBox(height: 10),
                Field(
                  Obscure: false,
                  inputtype: TextInputType.emailAddress,
                  controller: emailController,
                  t1: 'Email',
                  t2: 'parent@email.com',
                ),
                SizedBox(height: 10),
                Field(
                  Obscure: true,
                  inputtype: TextInputType.text,
                  controller: passwordController,
                  t1: 'Password',
                  t2: 'Create a strong password',
                ),
                SizedBox(height: 10),
                Field(
                  Obscure: true,
                  inputtype: TextInputType.text,
                  controller: confirmPasswordController,
                  t1: 'Confirm Password',
                  t2: 'Re-enter password',
                ),
                SizedBox(height: 10),
                Field(
                  Obscure: false,
                  inputtype: TextInputType.phone,
                  controller: phoneController,
                  t1: 'Phone (optional)',
                  t2: '+92 300 1234567',
                ),
                SizedBox(height: 30),
                Button(
                  t1: _busy ? 'Please wait…' : 'Create Account',
                  color: const Color(0xff38796D),
                  ontap: () {
                    if (_busy) return;
                    signup(
                      emailController.text.toString(),
                      passwordController.text.toString(),
                      confirmPasswordController.text.toString(),
                      usernameController.text.toString(),
                      phoneController.text.toString(),
                    );
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black26)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or',
                        style: GoogleFonts.poppins(color: Colors.black54),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.black26)),
                  ],
                ),
                SizedBox(height: 16),
                buildPlatformGoogleSignInButton(
                  onPressed: signupWithGoogle,
                  busy: _busy,
                ),
                SizedBox(height: 15),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signin1()),
                        );
                      },
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          color: Color(0xff38796D),
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
      ),
    );
  }
}
