import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/core_backend_service.dart';
import '../../auth/auth_service.dart';
import 'package:provider/provider.dart';
import '../../controllers/library_controller.dart';
import '../../utils/helper.dart';
import '../../auth/Signin1.dart';
import 'bottom_navigation/bottom_navigation.dart';

class ChildProfile extends StatefulWidget {
  final String parentName;
  final String? phone;

  const ChildProfile({
    super.key,
    required this.parentName,
    this.phone,
  });

  @override
  State<ChildProfile> createState() => _ChildProfileState();
}

class _ChildProfileState extends State<ChildProfile> {
  TextEditingController childNameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  String? selectedSound;
  String? selectedSoundName;

  bool isSaving = false;

  @override
  void dispose() {
    childNameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> saveChildProfile() async {
    final phoneVal = phoneController.text.trim();
    if (childNameController.text.trim().isEmpty || selectedSound == null) {
      Field.CustomAlertBox(context, 'Please fill in all fields');
      return;
    }

    if (phoneVal.isEmpty) {
      Field.CustomAlertBox(context, 'Phone number is compulsory. Please enter your contact number.');
      return;
    }

    final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,20}$');
    if (!phoneRegex.hasMatch(phoneVal)) {
      Field.CustomAlertBox(context, 'Please enter a valid phone number (7-20 digits).');
      return;
    }

    final uid = AuthService.instance.currentUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Field.CustomAlertBox(context, 'Please log in again.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final ageText = ageController.text.trim();
      final ageVal = ageText.isNotEmpty ? int.tryParse(ageText) : null;

      final success = await CoreBackendService().saveProfile(
        parentName: widget.parentName,
        childName: childNameController.text.trim(),
        age: ageVal,
        phone: phoneVal,
        sound: selectedSound,
        alphabetName: selectedSoundName,
      );

      if (!success) {
        if (!mounted) return;
        Field.CustomAlertBox(context, 'Failed to save profile. Please check connection.');
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavigation()),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (!mounted) return;
      Field.CustomAlertBox(context, 'Could not save profile: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<LibraryController>().loadAlphabets();
      try {
        final p = await CoreBackendService().getMyProfile();
        if (p != null && mounted) {
          final alphabets = context.read<LibraryController>().alphabets;
          setState(() {
            if (widget.phone != null && widget.phone!.trim().isNotEmpty && phoneController.text.isEmpty) {
              phoneController.text = widget.phone!.trim();
            }
            if (p['phone'] != null && phoneController.text.isEmpty) {
              phoneController.text = p['phone'].toString();
            }
            if (p['child_name'] != null && childNameController.text.isEmpty) {
              childNameController.text = p['child_name'].toString();
            }
            if (p['age'] != null && ageController.text.isEmpty) {
              ageController.text = p['age'].toString();
            }
            if (p['sound'] != null && selectedSound == null) {
              final rawSound = p['sound'].toString();
              if (alphabets.any((a) => a.letter == rawSound)) {
                selectedSound = rawSound;
                selectedSoundName = p['alphabet_name']?.toString();
              } else if (alphabets.isNotEmpty) {
                selectedSound = alphabets.first.letter;
                selectedSoundName = alphabets.first.name;
              }
            }
          });
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Tell us about your child",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await AuthService.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Signin1()),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18, color: Color(0xff38796D)),
                    label: Text(
                      'Log out',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xff38796D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Field(
                Obscure: false,
                inputtype: TextInputType.text,
                t1: 'Child\'s Name',
                t2: 'e.g. Ayesha',
                controller: childNameController,
              ),
              const SizedBox(height: 15),
              Field(
                Obscure: false,
                inputtype: TextInputType.number,
                t1: 'Child\'s Age',
                t2: 'e.g. 6',
                controller: ageController,
              ),
              const SizedBox(height: 15),
              Field(
                Obscure: false,
                inputtype: TextInputType.phone,
                t1: 'Parent\'s Phone Number (Compulsory)',
                t2: 'e.g. +923001234567',
                controller: phoneController,
              ),
              const SizedBox(height: 15),
              Text(
                'Focus Sound',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<LibraryController>(
                builder: (context, controller, _) {
                  if (controller.state == LoadState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.state == LoadState.error) {
                    return Text(
                      'Could not load sounds. Pull to retry.',
                      style: GoogleFonts.poppins(color: Colors.red),
                    );
                  }

                  final bool isValidSelection = controller.alphabets.any((a) => a.letter == selectedSound);
                  final String? dropdownValue = isValidSelection ? selectedSound : null;

                  return DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFFF3F0E9),
                    value: dropdownValue,
                    hint: Text('Select a sound', style: GoogleFonts.poppins()),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black26,
                        ),
                      ),
                    ),
                    items: controller.alphabets.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.letter,
                        child: Text(
                          '${a.letter}   (${a.name})',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedSound = value;
                        final match = controller.alphabets.where((a) => a.letter == value);
                        selectedSoundName = match.isNotEmpty ? match.first.name : null;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 36),
              Button(
                t1: isSaving ? 'Saving...' : 'Continue',
                color: const Color(0xff38796D),
                ontap: () {
                  if (!isSaving) saveChildProfile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
