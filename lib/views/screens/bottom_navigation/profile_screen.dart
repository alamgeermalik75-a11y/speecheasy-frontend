import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../services/core_backend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled1/views/screens/bottom_navigation/bottom_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/Signin1.dart';
import '../../../auth/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String childName = '';
  String parentName = '';
  int? age;
  String? phone;
  String? sound;
  String? alphabetName;
  bool hasPassword = false;
  bool isLoading = true;
  bool _isLoggingOut = false;

  String get currentUid =>
      AuthService.instance.currentUid ??
      (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await CoreBackendService().getMyProfile();
      if (data != null && mounted) {
        setState(() {
          childName = data['child_name'] ?? '';
          parentName = data['parent_name'] ?? '';
          age = data['age'] != null
              ? int.tryParse(data['age'].toString())
              : null;
          phone = data['phone'] != null ? data['phone'].toString() : null;
          sound = data['sound'] != null ? data['sound'].toString() : null;
          alphabetName = data['alphabet_name'] != null
              ? data['alphabet_name'].toString()
              : null;
        });
      }

      final hasPwd = await AuthService.instance.checkHasPassword();
      if (mounted) {
        setState(() {
          hasPassword = hasPwd;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> saveProfileEdits({
    required String newChildName,
    required String newParentName,
    int? newAge,
    String? newPhone,
  }) async {
    if (newChildName.isEmpty || newParentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both name fields.')),
      );
      return;
    }

    try {
      final ok = await CoreBackendService().saveProfile(
        childName: newChildName,
        parentName: newParentName,
        age: newAge,
        phone: (newPhone != null && newPhone.isNotEmpty) ? newPhone : null,
        sound: sound,
        alphabetName: alphabetName,
      );

      if (ok) {
        setState(() {
          childName = newChildName;
          parentName = newParentName;
          age = newAge;
          phone = newPhone;
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong. Try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  void showEditProfileSheet() {
    final childNameController = TextEditingController(text: childName);
    final ageController =
        TextEditingController(text: age != null ? age.toString() : '');
    final parentNameController = TextEditingController(text: parentName);
    final phoneController = TextEditingController(text: phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFFBF9F5),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: childNameController,
              decoration: InputDecoration(
                labelText: "Child's Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Child's Age",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: parentNameController,
              decoration: InputDecoration(
                labelText: 'Parent Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff38796D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final ageVal = int.tryParse(ageController.text.trim());
                  await saveProfileEdits(
                    newChildName: childNameController.text.trim(),
                    newParentName: parentNameController.text.trim(),
                    newAge: ageVal,
                    newPhone: phoneController.text.trim(),
                  );
                },
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSetPasswordSheet() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFFBF9F5),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set Password',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a password for your account so you can log in with both email and Google.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Min 8 chars, 1 letter & 1 number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setModalState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setModalState(
                        () => obscureConfirm = !obscureConfirm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff38796D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newPwd = newPasswordController.text;
                            final confPwd = confirmPasswordController.text;

                            if (newPwd.isEmpty || confPwd.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in both fields.'),
                                ),
                              );
                              return;
                            }
                            if (newPwd != confPwd) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Passwords do not match.'),
                                ),
                              );
                              return;
                            }
                            if (newPwd.length < 8 ||
                                !RegExp(r'[A-Za-z]').hasMatch(newPwd) ||
                                !RegExp(r'\d').hasMatch(newPwd)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password must be at least 8 characters and contain both letters and numbers.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            try {
                              await AuthService.instance.setPassword(newPwd);
                              if (!mounted) return;
                              Navigator.pop(context);
                              setState(() => hasPassword = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password set successfully.'),
                                ),
                              );
                            } on AuthApiException catch (e) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Set Password',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFFBF9F5),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your current password and choose a new secure password.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setModalState(
                        () => obscureCurrent = !obscureCurrent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Min 8 chars, 1 letter & 1 number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setModalState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setModalState(
                        () => obscureConfirm = !obscureConfirm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff38796D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final curPwd = currentPasswordController.text;
                            final newPwd = newPasswordController.text;
                            final confPwd = confirmPasswordController.text;

                            if (curPwd.isEmpty ||
                                newPwd.isEmpty ||
                                confPwd.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all fields.'),
                                ),
                              );
                              return;
                            }
                            if (newPwd != confPwd) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('New passwords do not match.'),
                                ),
                              );
                              return;
                            }
                            if (newPwd == curPwd) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'New password cannot be the same as your current password.',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (newPwd.length < 8 ||
                                !RegExp(r'[A-Za-z]').hasMatch(newPwd) ||
                                !RegExp(r'\d').hasMatch(newPwd)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'New password must be at least 8 characters with both letters and numbers.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            try {
                              await AuthService.instance.changePassword(
                                currentPassword: curPwd,
                                newPassword: newPwd,
                              );
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Password changed successfully.'),
                                ),
                              );
                            } on AuthApiException catch (e) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Update Password',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFFBF9F5),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Privacy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your child's practice data is encrypted and never shared with third parties without consent.",
              style: GoogleFonts.poppins(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteAccount();
              },
              child: Text(
                'Delete Account',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAboutSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFFBF9F5),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'About SpeakEasy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This app has been developed under the supervision of doctors and is specifically based on the book Articulation Disorder, written by the Head of the Speech Therapy Department at NIRM Hospital, Pakistan.',
              style: GoogleFonts.poppins(color: Colors.black54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void showHelpSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFFBF9F5),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          bool showAiAnswer = false;
          bool showBookingAnswer = false;

          return StatefulBuilder(
            builder: (context, setInnerState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Help & Support',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'How does scoring work?',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(
                        showAiAnswer ? Icons.expand_less : Icons.chevron_right,
                      ),
                      onTap: () =>
                          setInnerState(() => showAiAnswer = !showAiAnswer),
                    ),
                    if (showAiAnswer)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'When your child speaks into the mic, the app compares what it hears to the correct pronunciation and gives a score out of 100 based on how close the sounds match.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'How do I book a therapist?',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(
                        showBookingAnswer
                            ? Icons.expand_less
                            : Icons.chevron_right,
                      ),
                      onTap: () => setInnerState(
                        () => showBookingAnswer = !showBookingAnswer,
                      ),
                    ),
                    if (showBookingAnswer)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'After registering with your therapist, you can easily book a session by choosing an available date and time slot that is convenient for both you and your therapist, by tapping the registration card on home screen.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6F0EA),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: contactSupport,
                        child: Text(
                          'Contact Support',
                          style: GoogleFonts.poppins(
                            color: const Color(0xff38796D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@speakeasy-app.com',
      query: 'subject=SpeakEasy Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }

  Future<void> deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete your child\'s profile and all practice data. This cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: const Color(0xffC0432A)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CoreBackendService().deleteMyProfile();
      await FirebaseAuth.instance.currentUser?.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Signin1()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not delete account. You may need to log in again first.',
            ),
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Log Out',
              style: GoogleFonts.poppins(
                color: const Color(0xffC0432A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (mounted) setState(() => _isLoggingOut = true);

    try {
      await AuthService.instance.signOut().timeout(
        const Duration(seconds: 2),
        onTimeout: () => debugPrint('AuthService signOut timed out'),
      );
    } catch (e) {
      debugPrint('Error signing out AuthService: $e');
    }

    try {
      await FirebaseAuth.instance.signOut().timeout(
        const Duration(seconds: 1),
        onTimeout: () => null,
      );
    } catch (_) {}

    try {
      await GoogleSignIn.instance.signOut().timeout(
        const Duration(seconds: 1),
        onTimeout: () => null,
      );
    } catch (_) {}

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Signin1()),
        (route) => false,
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.black45,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE0)),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppBar(
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BottomNavigation(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFBAB49B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_backspace_sharp,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title: Text(
              'Profile',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE HEADER (AVATAR & NAMES) ---
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6F0EA),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xff38796D).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text('👦', style: TextStyle(fontSize: 36)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          childName.isNotEmpty ? childName : 'Child',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        if (parentName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Parent: $parentName',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // --- SECTION 1: PERSONAL / CHILD INFORMATION ---
                  _buildSectionHeader('PERSONAL / CHILD INFORMATION'),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Child Name',
                          childName.isNotEmpty ? childName : '—',
                        ),
                        const Divider(height: 18),
                        _buildInfoRow(
                          'Parent Name',
                          parentName.isNotEmpty ? parentName : '—',
                        ),
                        const Divider(height: 18),
                        _buildInfoRow(
                          'Age',
                          age != null ? '$age years' : 'Not specified',
                        ),
                        const Divider(height: 18),
                        _buildInfoRow(
                          'Phone',
                          (phone != null && phone!.isNotEmpty)
                              ? phone!
                              : 'Not specified',
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xff38796D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: showEditProfileSheet,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 2: ACCOUNT & SECURITY ---
                  _buildSectionHeader('ACCOUNT & SECURITY'),
                  _buildCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6F0EA).withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Color(0xff38796D),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Password',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        hasPassword ? 'Password is set' : 'Not set',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: hasPassword
                              ? const Color(0xff2E7D32)
                              : Colors.black45,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasPassword ? 'Change Password' : 'Set Password',
                            style: GoogleFonts.poppins(
                              color: const Color(0xff38796D),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Color(0xff38796D),
                          ),
                        ],
                      ),
                      onTap: hasPassword
                          ? showChangePasswordSheet
                          : showSetPasswordSheet,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 3: PRIVACY & SUPPORT ---
                  _buildSectionHeader('PREFERENCES & SUPPORT'),
                  _buildCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.privacy_tip_outlined,
                            size: 20,
                            color: Colors.black54,
                          ),
                          title: Text(
                            'Privacy',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.black38,
                          ),
                          onTap: showPrivacySheet,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.help_outline,
                            size: 20,
                            color: Colors.black54,
                          ),
                          title: Text(
                            'Help & Support',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.black38,
                          ),
                          onTap: showHelpSheet,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.black54,
                          ),
                          title: Text(
                            'About',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.black38,
                          ),
                          onTap: showAboutSheet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- LOG OUT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xffC0432A)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.logout,
                        size: 18,
                        color: Color(0xffC0432A),
                      ),
                      onPressed: _isLoggingOut ? null : logout,
                      label: _isLoggingOut
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xffC0432A),
                              ),
                            )
                          : Text(
                              'Log Out',
                              style: GoogleFonts.poppins(
                                color: const Color(0xffC0432A),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}