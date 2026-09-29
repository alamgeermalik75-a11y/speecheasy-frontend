import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/views/screens/bottom_navigation/libraryscreens1.dart';
import 'Signin1.dart';

class Checkuser extends StatefulWidget {
  const Checkuser({super.key});

  @override
  State<Checkuser> createState() => _CheckuserState();
}

class _CheckuserState extends State<Checkuser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  checkuser() async{
    final user = FirebaseAuth.instance.currentUser;
    if(user!= null){
      return LibraryScreen();
    }
    else{
      return Signin1();
    }
  }
}
