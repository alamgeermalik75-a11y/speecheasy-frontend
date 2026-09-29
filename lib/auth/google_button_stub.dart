import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildPlatformGoogleSignInButton({
  required VoidCallback onPressed,
  bool busy = false,
}) {
  return OutlinedButton.icon(
    onPressed: busy ? null : onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      side: const BorderSide(color: Color(0xFFDADCE0)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.white,
    ),
    icon: const FaIcon(
      FontAwesomeIcons.google,
      size: 18,
      color: Color(0xFFEA4335),
    ),
    label: Text(
      'Continue with Google',
      style: GoogleFonts.poppins(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
