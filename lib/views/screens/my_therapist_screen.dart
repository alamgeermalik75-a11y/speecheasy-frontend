import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/core_backend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled1/views/screens/book_session_screen.dart';
import 'sessions_screen.dart';
import '../../auth/auth_service.dart';

class MyTherapistScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final Map<String, dynamic> patientRow;

  const MyTherapistScreen({super.key, required this.doctor, required this.patientRow});

  @override
  State<MyTherapistScreen> createState() => _MyTherapistScreenState();
}

class _MyTherapistScreenState extends State<MyTherapistScreen> {
  bool isUnregistering = false;
  int myRating = 0;
  bool isSubmittingRating = false;
  String get currentPatientUid => AuthService.instance.currentUid ?? (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    fetchMyRating();
  }

  Future<void> fetchMyRating() async {
    try {
      final rating = await CoreBackendService().getMyRating(widget.doctor['id'].toString());
      if (rating != null && mounted) {
        setState(() => myRating = rating);
      }
    } catch (e) {
      print('Error fetching my rating: $e');
    }
  }

  Future<void> submitRating(int stars) async {
    setState(() => isSubmittingRating = true);
    try {
      final success = await CoreBackendService().submitRating(widget.doctor['id'].toString(), stars);
      if (success) {
        if (mounted) {
          setState(() => myRating = stars);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanks for your rating!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not submit rating. Try again.')),
          );
        }
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmittingRating = false);
    }
  }

  Future<void> unregister() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unregister from this doctor?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        content: Text(
          "They'll no longer be able to see your child's practice and progress.",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unregister', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isUnregistering = true);
    try {
      final success = await CoreBackendService().unregisterDoctor();
      if (success && mounted) {
        Navigator.pop(context, true); // true = tell Home to refresh
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not unregister. Try again.')),
        );
      }
    } catch (e) {
      print('Error unregistering: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isUnregistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize:  Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
            scrolledUnderElevation: 0,

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
            backgroundColor: Colors.transparent,
            title: Text('My Therapist', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFf3f0e9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEDEAE0)),
              ),
              child: Column(
                children: [
                  CircleAvatar(radius: 32, child: Text('🧑‍⚕️', style: TextStyle(fontSize: 28))),
                  SizedBox(height: 12),
                  Text(
                    doctor['full_name'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doctor['qualification'] ?? ''} · ${doctor['years_of_experience'] ?? '?'} yrs experience',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F0EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '✓ Registered',
                      style: GoogleFonts.poppins(color: const Color(0xff2E6F65), fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFf3f0e9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDEAE0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: CupertinoColors.activeBlue,),
                    title: Text('Languages', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),

                    subtitle: Text(doctor['languages_spoken'] ?? '', style: GoogleFonts.poppins(color: Colors.black54)),
                  ),
                  const Divider(height: 1, color: Colors.black54, thickness: 0.7,),
                  ListTile(
                    leading: const Icon(Icons.star, color: CupertinoColors.systemYellow,),
                    title: Text('Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('${doctor['rating'] ?? 'N/A'}', style: GoogleFonts.poppins(color: Colors.black54)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf3f0e9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDEAE0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate this doctor', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      return IconButton(
                        icon: Icon(
                          starNumber <= myRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFE8B344),
                          size: 32,
                        ),
                        onPressed: isSubmittingRating ? null : () => submitRating(starNumber),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff38796D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SessionsScreen(),
                    ),
                  );
                },
                child: Text('View My Sessions', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff5B6FB0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookSessionScreen(
                        doctor: doctor,
                        patientName: widget.patientRow['name'] ?? '',
                      ),
                    ),
                  );
                },
                child: Text('Book a Session', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xffC0432A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: isUnregistering ? null : unregister,
                child: Text('Unregister from this Doctor', style: GoogleFonts.poppins(color: Color(0xffC0432A), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}