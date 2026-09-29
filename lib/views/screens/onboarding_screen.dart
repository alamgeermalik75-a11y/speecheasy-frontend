import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:untitled1/auth/Signin1.dart';
import '../../utils/helper.dart';
import 'homescreen.dart';

class First extends StatefulWidget {
  const First({super.key});

  @override
  State<First> createState() => _FirstState();
}

class _FirstState extends State<First> {
  PageController pageController = PageController();
  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFBF9F5),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
        child: Column(
          children: [
              InkWell(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Skip", style: GoogleFonts.poppins(color: Color(0xFF38796D), fontSize: 15, fontWeight: FontWeight.bold),),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> Signin1())
                    );
                  },
                ),
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                children: [
                  Container(
                    color: Color(0xFFFBF9F5),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Helper(
                      image: 'assets/images/img9.png',
                      t1: 'Practice speech sounds together, every day.',
                      t2: "Turn your child's therapy book into a fun daily habit, guided step by step.",
                      c2: Colors.black,
                      c3: Colors.black54,
                    ),
                  ),
                  Container(
                    color: Color(0xFFFBF9F5),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Helper(
                      image: 'assets/images/img10.png',
                      t1: 'Instant feedback, no waiting for reports.',
                      t2: "Every attempt is scored right away, so your child stays motivated in the moment.",
                      c2: Colors.black,
                      c3: Colors.black54,
                    ),
                  ),
                  Container(
                    color: Color(0xFFFBF9F5),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Helper(
                      image: 'assets/images/img2.png',
                      t1: 'Connect with real speech therapists when you need to.',
                      t2: 'Book an online consultation whenever extra support helps.',
                      c2: Colors.black,
                      c3: Colors.black54,
                    ),
                  ),

                ],
              ),
            ),
            SmoothPageIndicator(
              controller: pageController,
              count: 3,
              effect: ExpandingDotsEffect(
                activeDotColor: Color(0xFF38796D),
                dotColor: Colors.grey.shade300,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            SizedBox(height: 30,),
            ElevatedButton(
              onPressed: () {
                if (currentPage == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Homescreen(),
                    ),
                  );
                } else {
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(
                currentPage == 2 ? "Get Started" : "Next", style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(350, 50),
                backgroundColor: Color(0xFF38796D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}
