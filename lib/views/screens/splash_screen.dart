import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const First()),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF14453F),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
        child: SizedBox.expand(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            Image(image: AssetImage("assets/images/img4.png")),
            SizedBox(height: 10),
            Text(
              'SpeakEasy',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Speech therapy, made easy',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
            ),
            SizedBox(height: 140),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE8B344),
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10,),
            Text(
                'Loading your session...',
                style: GoogleFonts.poppins(color: Colors.white)
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
