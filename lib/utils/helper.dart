import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Helper extends StatelessWidget {
  String image;
  Color c2;
  Color c3;
  String t1;
  String t2;

  Helper({
    super.key,
    required this.image,
    required this.t1,
    required this.t2,
    required this.c2,
    required this.c3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image(height: 220, width: 220, image: AssetImage(image)),
        SizedBox(height: 20),
        Text(
          textAlign: TextAlign.center,
          t1,
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: c2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          textAlign: TextAlign.center,
          t2,
          style: GoogleFonts.poppins(fontSize: 13, color: c3),
        ),
      ],
    );
  }
}

class Button extends StatelessWidget {
  String t1;
  VoidCallback ontap;
  Color color;
  Button({required this.t1, required this.color, required this.ontap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t1,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

class Field extends StatelessWidget {
  String t1;
  String t2;
  bool Obscure;
  TextInputType inputtype;
  TextEditingController controller;
  Field({
    super.key,
    required this.t1,
    required this.t2,
    required this.controller,
    required this.Obscure,
    required this.inputtype
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t1,
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          obscureText: Obscure,
          keyboardType: inputtype,
          controller: controller,
          decoration: InputDecoration(

            hintText: t2,
            hintStyle: GoogleFonts.poppins(color: Colors.black54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  static CustomAlertBox(BuildContext context, String text) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(text),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class Grid extends StatelessWidget {
  final String text;
  final String img;
  const Grid({super.key, required this.text, required this.img});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFf3f0e9),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                img,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

