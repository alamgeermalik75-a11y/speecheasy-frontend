import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/core_backend_service.dart';
import '../../auth/auth_service.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  List<Map<String, dynamic>> therapists = [];
  bool isLoading = true;

  String get currentUid => AuthService.instance.currentUid ?? (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    fetchTherapists();
  }

  Future<void> fetchTherapists() async {
    try {
      final data = await CoreBackendService().getTherapists();
      setState(() {
        therapists = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching therapists: $e');
      setState(() => isLoading = false);
    }
  }
  void requestTherapist(Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFf3f0e9),
        title: Text('Register with ${therapist['full_name']}?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "They'll see your request and can accept it. Once accepted, they'll be able to follow your child's practice and progress.",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff38796D)),
            onPressed: () async {
              Navigator.pop(context);
              await submitRequest(therapist);
            },
            child: Text('Send Request', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Widget buildCodeEntryCard() {
    final codeController = TextEditingController();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFf3f0e9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a doctor\'s code?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter it below to send them a registration request directly.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. SPK-1234',
                    filled: true,
                    fillColor: Color(0xFFFBF9F5).withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff38796D),
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => submitByCode(codeController.text.trim()),
                child: Text('Send', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> submitByCode(String code) async {
    if (code.isEmpty) return;

    try {
      final therapist = await CoreBackendService().getTherapistByCode(code);
      if (therapist == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No doctor found with that code.')),
        );
        return;
      }
      requestTherapist(therapist);
    } catch (e) {
      print('Error looking up doctor by code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  Future<void> submitRequest(Map<String, dynamic> therapist) async {
    try {
      final res = await CoreBackendService().requestTherapist(therapist['id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Done')),
        );
        if (res['success'] == true) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error submitting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            title: Text('Find Doctor', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: buildCodeEntryCard(),
          ),
          Expanded(
            child: therapists.isEmpty
                ? Center(
              child: Text(
                'No therapists available yet.',
                style: GoogleFonts.poppins(color: Colors.black45),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: therapists.length,
              itemBuilder: (context, index) {
                final t = therapists[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFf3f0e9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDEAE0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        leading: CircleAvatar(
                          radius: 40,
                          child: Text('🧑‍⚕️', style: TextStyle(fontSize: 25),),
                        ),
                        title:Text(
                          t['full_name'] ?? 'Unnamed',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  t['qualification'] ?? '',
                                  style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
                                ),
                                SizedBox(width: 4),
                                Text("⋅", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                                SizedBox(width: 4),
                                if (t['years_of_experience'] != null)
                                  Text(
                                    '${t['years_of_experience']} years experience',
                                    style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '🗣️ ${t['languages_spoken'] ?? ''}',
                                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                ),
                                SizedBox(width: 10),
                                if (t['rating'] != null)
                                  Text(
                                    '⭐ ${t['rating']}',
                                    style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                  ),
                              ],
                            ),
                            SizedBox(height: 5,),
                            Text('Rs. ${t['consultation_fee'] ?? 0}/ session',
                              style: GoogleFonts.poppins(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff38796D),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),

                          onPressed: () => requestTherapist(t),
                          child: Text('Register', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}