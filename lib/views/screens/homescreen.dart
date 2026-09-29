import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/Signin1.dart';
import '../../auth/signup.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  bool isparent = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFBF9F5),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Color(0xFF38796D),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF38796D),
                    blurRadius: 0.4,
                    spreadRadius: 0.9,
                  ),
                ],
              ),
              child: Icon(Icons.mic_none, size: 40, color: Colors.white),
            ),
            SizedBox(height: 40),
            Text(
              textAlign: TextAlign.center,
              "Welcome to SpeakEasy",
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              textAlign: TextAlign.center,
              "Sign in to continue the practice journey.",
              style: GoogleFonts.poppins(fontSize: 17, color: Colors.black54),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isparent ? Color(0xFF38796D) :  Color(0xff6577BE),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                minimumSize: Size(double.infinity, 60)
              ),
              onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> Signin1()));
              },

              child: Text(
                'Log In',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20,),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: isparent ? Color(0xFF38796D) :  Color(0xff6577BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                  side: BorderSide(
                    color: const Color(0xff38796D),
                  ),
                  minimumSize: Size(double.infinity, 60)
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> Signup()));
              },
              child: Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20,),
            Text('Practicing at home with your child.', style: GoogleFonts.poppins(color: Colors.black54),)
          ],
        ),
      ),
    );
  }
}
