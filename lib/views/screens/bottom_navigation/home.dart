import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/utils/helper.dart';
import '../../../services/core_backend_service.dart';
import '../../../auth/auth_service.dart';
import 'package:untitled1/views/screens/bottom_navigation/libraryscreens1.dart';
import 'package:untitled1/views/screens/bottom_navigation/progress_screen.dart';
import 'package:untitled1/views/screens/chatbot_screen.dart';
import 'package:untitled1/views/screens/find_doctor_screen.dart';

import '../../../controllers/library_controller.dart';
import '../../../models/alphabet.dart';
import '../my_therapist_screen.dart';
import '../notifications_screen.dart';
import '../sounddetailscreens3.dart';
import '../child_profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String get currentUid => AuthService.instance.currentUid ?? (FirebaseAuth.instance.currentUser?.uid ?? '');
  String currentSound = 'ا';
  double currentProgress = 0.0;
  bool isLoading = true;
  String parentName = '';
  String childName = '';
  String dailyTip = 'Loading tip...';
  int unreadCount = 0;
  Map<String, dynamic>? myDoctorRequest; // null, or a row from patient_requests / patients
  bool doctorLinked = false;
  Map<String, dynamic>? myDoctorInfo;
  bool profileLoading = true;
  Timer? _doctorPollTimer;

  @override
  void initState() {
    super.initState();
    parentName = AuthService.instance.parentNameHint();
    fetchHomeData();
    fetchDailyTip();
    fetchUnreadCount();
    fetchMyDoctorStatus();
    _startDoctorPolling();
    Future.microtask(() => context.read<LibraryController>().loadAlphabets());
  }

  @override
  void dispose() {
    _doctorPollTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchHomeData() async {
    setState(() => profileLoading = true);
    try {
      final profile = await CoreBackendService().getMyProfile();
      if (profile != null && mounted) {
        setState(() {
          final p = profile['parent_name']?.toString();
          if (p != null && p.isNotEmpty) {
            parentName = p;
          } else if (parentName.isEmpty) {
            parentName = AuthService.instance.parentNameHint();
          }
          final c = profile['child_name']?.toString();
          if (c != null && c.isNotEmpty) {
            childName = c;
          }
          final focus = profile['focus_sound'];
          if (focus != null) {
            currentSound = focus['sound'] ?? currentSound;
            currentProgress = (focus['progress'] as num?)?.toDouble() ?? 0.0;
          }
          isLoading = false;
          profileLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching profile and focus sound: $e');
    }
    if (mounted) {
      setState(() {
        if (parentName.isEmpty) {
          parentName = AuthService.instance.parentNameHint();
        }
        isLoading = false;
        profileLoading = false;
      });
    }
  }

  Future<void> fetchFocusSound() async {
    await fetchHomeData();
  }

  Future<void> fetchProfile() async {
    await fetchHomeData();
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await CoreBackendService().getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          unreadCount = count;
        });
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  Future<void> fetchDailyTip() async {
    try {
      final tips = await CoreBackendService().getDailyTips();
      if (tips.isNotEmpty && mounted) {
        final dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
        final tipIndex = dayOfYear % tips.length;
        setState(() {
          dailyTip = tips[tipIndex]['tip_text'] ?? dailyTip;
        });
      }
    } catch (e) {
      print('Error fetching daily tip: $e');
    }
  }

  void _startDoctorPolling() {
    _doctorPollTimer?.cancel();
    _doctorPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _pollDoctorStatus();
    });
  }

  Future<void> _pollDoctorStatus() async {
    try {
      final res = await CoreBackendService().getMyDoctorStatus();
      if (!mounted) return;

      if (res != null) {
        final status = res['status'];
        if (status == 'approved') {
          final wasNotLinked = !doctorLinked;
          setState(() {
            doctorLinked = true;
            myDoctorInfo = res['doctor'];
            myDoctorRequest = {'doctor_id': res['doctor']?['id']};
          });

          if (wasNotLinked) {
            fetchUnreadCount();
            final docName = myDoctorInfo?['full_name'] ?? 'Your doctor';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🎉 Great news! Dr. $docName has accepted your registration request.',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xff38796D),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else if (status == 'pending') {
          if (doctorLinked || myDoctorRequest == null) {
            setState(() {
              doctorLinked = false;
              myDoctorRequest = res['request'];
            });
          }
        } else {
          if (doctorLinked || myDoctorRequest != null) {
            setState(() {
              doctorLinked = false;
              myDoctorRequest = null;
              myDoctorInfo = null;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> fetchMyDoctorStatus() async {
    if (!mounted) return;
    try {
      final res = await CoreBackendService().getMyDoctorStatus();
      if (res != null && mounted) {
        final status = res['status'];
        if (status == 'approved') {
          setState(() {
            doctorLinked = true;
            myDoctorInfo = res['doctor'];
            myDoctorRequest = {'doctor_id': res['doctor']?['id']};
          });
        } else if (status == 'pending') {
          setState(() {
            doctorLinked = false;
            myDoctorRequest = res['request'];
            myDoctorInfo = null;
          });
        } else {
          setState(() {
            doctorLinked = false;
            myDoctorRequest = null;
            myDoctorInfo = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching doctor status: $e');
    }
  }
  void continuePractice() async {
    final library = context.read<LibraryController>();

    if (library.alphabets.isEmpty) {
      await library.loadAlphabets();
    }

    Alphabet? match;
    for (final a in library.alphabets) {
      if (a.letter == currentSound) {
        match = a;
        break;
      }
    }

    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sound not found. Try opening Library first.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SoundDetailScreen(alphabet: match!)),
    );
    fetchFocusSound();
  }
  Widget buildMyDoctorCard() {
    String title;
    String subtitle;
    String trailingText = '';

    if (myDoctorRequest == null) {
      title = 'Find a Doctor';
      subtitle = 'Register so a therapist can follow along';
    } else if (doctorLinked) {
      title = '$childName, registered with Dr. ${myDoctorInfo?['full_name'] ?? ''}';
      subtitle = myDoctorInfo?['qualification'] ?? '';
      trailingText = '';
    } else {
      title = 'Request pending';
      subtitle = 'Waiting for the therapist to accept';
      trailingText = '⏳';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: const Color(0xFFf3f0e9),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 23,
          child: Text('🩺', style: TextStyle(fontSize: 19)),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.black54)),
        trailing: trailingText.isNotEmpty
            ? Text(trailingText, style: const TextStyle(fontSize: 18))
            : Icon(Icons.chevron_right_outlined, color: Color(0xFF2E6F65)),
        onTap: () async {
          if (myDoctorRequest == null) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
            );
            fetchMyDoctorStatus();
          } else if (doctorLinked && myDoctorInfo != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyTherapistScreen(doctor: myDoctorInfo!, patientRow: myDoctorRequest!)),
            );
            fetchMyDoctorStatus();
          }
          // pending state: tapping does nothing now, just shows the status
        },
      ),
    );
  }
  // void _showEnterCodeDialog() {
  //   final codeController = TextEditingController();
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: Color(0xFFf3f0e9),
  //       title: Text('Enter Practice Code', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
  //       content: TextField(
  //         controller: codeController,
  //         decoration: const InputDecoration(hintText: 'e.g. SPK-1234'),
  //         textCapitalization: TextCapitalization.characters,
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Cancel', style: GoogleFonts.poppins()),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff38796D)),
  //           onPressed: () async {
  //             final code = codeController.text.trim();
  //             if (code.isEmpty) return;
  //             Navigator.pop(context);
  //             await _linkWithCode(code);
  //           },
  //           child: Text('Link', style: GoogleFonts.poppins(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize:  Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: CircleAvatar(
                child: Text('🧑'),
                backgroundColor: Color(0xFFBAB49B).withOpacity(0.2),
              ),
            ),
            title: Text(
              parentName,
              style: GoogleFonts.poppins(color: Colors.black),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(),
                      ),
                    );
                    fetchUnreadCount();
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBAB49B).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.black54,
                          size: 18,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: (isLoading || profileLoading)
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (childName.isNotEmpty && childName != 'Child')
                      ? 'Good Morning $childName'
                      : 'Good Morning!',
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                if (childName.isEmpty || childName == 'Child') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2ECE1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDECFC0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.child_care_rounded, color: Color(0xFF38796D), size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Personalize Your Profile",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Set your child's name and focus sound.",
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff38796D),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildProfile(
                                  parentName: parentName.isNotEmpty ? parentName : AuthService.instance.parentNameHint(),
                                ),
                              ),
                            );
                            fetchHomeData();
                          },
                          child: Text(
                            "Setup",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 17),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFD6F0EA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S PRACTICE",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Color(0XFF3F8E58),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Practice the $currentSound sound',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: currentProgress,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2F6F5E),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff38796D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: continuePractice,
                        child: Text(
                          'Continue Practice',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  children: [
                    InkWell(
                      child: Grid(text: 'Find Doctor', img: "assets/images/img5.png"),
                      onTap: () {
                        fetchMyDoctorStatus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FindDoctorScreen(),
                          ),
                        );
                      },
                    ),
                    InkWell(
                      child: Grid(text: 'AI chatbot', img: "assets/images/img7.png"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatbotScreen(),
                          ),
                        );
                      },
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LibraryScreen(),
                          ),
                        );
                      },
                      child: Grid(text: 'Library', img: "assets/images/img6.png"),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgressScreen(),
                          ),
                        );
                      },
                      child: Grid(text: 'Progress', img: "assets/images/img8.png"),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                buildMyDoctorCard(),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE4D6),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Daily Tip',
                        style: GoogleFonts.poppins(
                          color: Color(0xFFB5502a),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        dailyTip,
                        style: GoogleFonts.poppins(color: Color(0xFF7A3A1F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
