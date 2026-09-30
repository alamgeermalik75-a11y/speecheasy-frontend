import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled1/auth/auth_service.dart';
import 'package:untitled1/auth/signup.dart';
import 'package:untitled1/auth/verify_email_screen.dart';
import 'package:untitled1/views/screens/bottom_navigation/bottom_navigation.dart';
import 'package:untitled1/views/screens/child_profile.dart';
import '../utils/helper.dart';
import '../services/patient_auth_service.dart';
import 'google_button.dart';
import 'forgot.dart';

class Signin1 extends StatefulWidget {
  const Signin1({super.key});

  @override
  State<Signin1> createState() => _Signin1State();
}

class _Signin1State extends State<Signin1> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    PatientAuthService.instance.onGoogleSignInSuccess = null;
    PatientAuthService.instance.onGoogleSignInError = null;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    PatientAuthService.instance.onGoogleSignInSuccess = () {
      if (mounted) {
        if (!AuthService.instance.isEmailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                parentName: AuthService.instance.parentNameHint(),
                goToChildProfileWhenDone: false,
              ),
            ),
          );
          return;
        }
        _goAfterAuth();
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

  Future<void> _goAfterAuth() async {
    if (!mounted) return;
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

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      Field.CustomAlertBox(context, 'Enter Required Fields');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      if (!AuthService.instance.isEmailVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              parentName: AuthService.instance.parentNameHint(),
              goToChildProfileWhenDone: false,
            ),
          ),
        );
        return;
      }
      await _goAfterAuth();
    } on AuthApiException catch (ex) {
      if (!mounted) return;
      if (ex.code == 'EMAIL_NOT_VERIFIED') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              parentName: AuthService.instance.parentNameHint(),
              goToChildProfileWhenDone: false,
            ),
          ),
        );
      } else {
        Field.CustomAlertBox(context, ex.message);
      }
    } catch (e) {
      if (!mounted) return;
      Field.CustomAlertBox(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> loginWithGoogle() async {
    setState(() => _busy = true);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result != null) {
        // Mobile: result is immediately available
        if (!AuthService.instance.isEmailVerified) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                parentName: AuthService.instance.parentNameHint(),
                goToChildProfileWhenDone: false,
              ),
            ),
          );
          return;
        }
        await _goAfterAuth();
      }
      // Web: result is null because sign-in is via GIS button pop-up
      // Navigation happens via onGoogleSignInSuccess callback set in initState
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
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize:  Size.fromHeight(50.0),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Log in to continue practicing.',
                  style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
                ),
                SizedBox(height: 20),
                Field(
                  Obscure: false,
                  inputtype: TextInputType.emailAddress,
                  controller: emailController,
                  t1: 'Email',
                  t2: 'your@gmail.com',
                ),
                SizedBox(height: 20),
                Field(
                  Obscure: true,
                  inputtype: TextInputType.text,
                  controller: passwordController,
                  t1: 'Password',
                  t2: 'your password',
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: Color(0xff38796D),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Forgot()),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Button(
                  color: const Color(0xff38796D),
                  t1: _busy ? 'Please wait…' : 'Log In',
                  ontap: () {
                    if (_busy) return;
                    login(
                      emailController.text.toString(),
                      passwordController.text.toString(),
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
                  onPressed: loginWithGoogle,
                  busy: _busy,
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "New here?",
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signup()),
                        );
                      },
                      child: Text(
                        'Create Account',
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
