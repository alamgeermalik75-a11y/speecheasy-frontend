import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled1/views/screens/bottom_navigation/home.dart';
import 'package:untitled1/views/screens/bottom_navigation/libraryscreens1.dart';
import 'package:untitled1/views/screens/bottom_navigation/profile_screen.dart';
import 'package:untitled1/views/screens/bottom_navigation/progress_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int myIndex = 0;
  final List<Widget> pages =[
    Home(),
    LibraryScreen(),
    ProgressScreen(),
    ProfileScreen()
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[myIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        fixedColor: Colors.black,
        unselectedLabelStyle: GoogleFonts.poppins(
          color: Colors.black
        ),
         selectedLabelStyle: GoogleFonts.poppins(
             color: Colors.black
         ),
        onTap: (index){
          setState(() {
            myIndex = index;
          });
        },
        currentIndex: myIndex,
        backgroundColor:  Color(0xFFF4F1EC),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined,color: Colors.black,), label: 'Home',  ),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined,color: Colors.black,), label: 'Library', ),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up,color: Colors.black,), label: 'Progress',  ),
          BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined, color: Colors.black,), label: 'Profile', ),

        ],
      ),
    );
  }
}
