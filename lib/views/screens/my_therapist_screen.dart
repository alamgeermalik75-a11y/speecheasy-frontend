import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/core_backend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled1/views/screens/book_session_screen.dart';
import 'find_doctor_screen.dart';
import 'sessions_screen.dart';
import '../../auth/auth_service.dart';

enum TherapistLinkState { loading, notLinked, pending, approved, error }

class MyTherapistScreen extends StatefulWidget {
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? patientRow;

  const MyTherapistScreen({super.key, this.doctor, this.patientRow});

  @override
  State<MyTherapistScreen> createState() => _MyTherapistScreenState();
}

class _MyTherapistScreenState extends State<MyTherapistScreen> {
  TherapistLinkState _linkState = TherapistLinkState.loading;
  Map<String, dynamic>? _doctor;
  Map<String, dynamic>? _patientRow;
  Map<String, dynamic>? _pendingRequest;
  bool isUnregistering = false;
  int myRating = 0;
  bool isSubmittingRating = false;
  Timer? _pollTimer;

  String get currentPatientUid => AuthService.instance.currentUid ?? (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    if (widget.doctor != null && widget.doctor!.isNotEmpty) {
      _doctor = widget.doctor;
      _patientRow = widget.patientRow;
      _linkState = TherapistLinkState.approved;
      fetchMyRating();
    }
    _loadDoctorStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _pollDoctorStatusSilently();
    });
  }

  Future<void> _pollDoctorStatusSilently() async {
    try {
      final res = await CoreBackendService().getMyDoctorStatus();
      if (!mounted || res == null) return;

      final statusStr = res['status'] ?? 'none';
      if (statusStr == 'approved') {
        final doc = res['doctor'] as Map<String, dynamic>?;
        if (_doctor?['id']?.toString() != doc?['id']?.toString() || _linkState != TherapistLinkState.approved) {
          setState(() {
            _doctor = doc;
            _patientRow = res['patient'] as Map<String, dynamic>? ?? _patientRow;
            _pendingRequest = null;
            _linkState = TherapistLinkState.approved;
          });
          fetchMyRating();
        }
      } else if (statusStr == 'pending') {
        if (_linkState != TherapistLinkState.pending) {
          setState(() {
            _pendingRequest = res['request'] as Map<String, dynamic>?;
            _doctor = null;
            _linkState = TherapistLinkState.pending;
          });
        }
      } else {
        if (_linkState != TherapistLinkState.notLinked) {
          setState(() {
            _doctor = null;
            _pendingRequest = null;
            _linkState = TherapistLinkState.notLinked;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadDoctorStatus() async {
    try {
      final res = await CoreBackendService().getMyDoctorStatus();
      if (!mounted) return;

      if (res == null) {
        if (_doctor == null) {
          setState(() => _linkState = TherapistLinkState.notLinked);
        }
        return;
      }

      final statusStr = res['status'] ?? 'none';
      if (statusStr == 'approved') {
        setState(() {
          _doctor = res['doctor'] as Map<String, dynamic>?;
          _patientRow = res['patient'] as Map<String, dynamic>? ?? _patientRow;
          _pendingRequest = null;
          _linkState = TherapistLinkState.approved;
        });
        fetchMyRating();
      } else if (statusStr == 'pending') {
        setState(() {
          _pendingRequest = res['request'] as Map<String, dynamic>?;
          _doctor = null;
          _linkState = TherapistLinkState.pending;
        });
      } else {
        setState(() {
          _doctor = null;
          _pendingRequest = null;
          _linkState = TherapistLinkState.notLinked;
        });
      }
    } catch (e) {
      if (mounted && _doctor == null) {
        setState(() => _linkState = TherapistLinkState.error);
      }
    }
  }

  Future<void> fetchMyRating() async {
    final docId = _doctor?['id']?.toString();
    if (docId == null) return;
    try {
      final rating = await CoreBackendService().getMyRating(docId);
      if (rating != null && mounted) {
        setState(() => myRating = rating);
      }
    } catch (e) {
      debugPrint('Error fetching my rating: $e');
    }
  }

  Future<void> submitRating(int stars) async {
    final docId = _doctor?['id']?.toString();
    if (docId == null) return;

    setState(() => isSubmittingRating = true);
    try {
      final success = await CoreBackendService().submitRating(docId, stars);
      if (success && mounted) {
        setState(() => myRating = stars);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your rating!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit rating. Try again.')),
        );
      }
    } catch (e) {
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
        backgroundColor: const Color(0xFFFBF9F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Unregister from this doctor?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        content: Text(
          "They'll no longer be able to see your child's practice, appointments, and progress.",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0432A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unregister', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isUnregistering = true);
    try {
      final success = await CoreBackendService().unregisterDoctor();
      if (success && mounted) {
        setState(() {
          _doctor = null;
          _linkState = TherapistLinkState.notLinked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unregistered successfully.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not unregister. Try again.')),
        );
      }
    } catch (e) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFBAB49B).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.keyboard_backspace_sharp, color: Colors.black),
                ),
              ),
            ),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title: Text(
              'My Therapist',
              style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF38796D)),
                tooltip: 'Refresh',
                onPressed: _loadDoctorStatus,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_linkState == TherapistLinkState.loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38796D)));
    }

    if (_linkState == TherapistLinkState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Could not load therapist info. Please check your internet connection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38796D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadDoctorStatus,
                child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_linkState == TherapistLinkState.notLinked) {
      return _buildDoctorRequiredView();
    }

    if (_linkState == TherapistLinkState.pending) {
      return _buildPendingApprovalView();
    }

    return _buildApprovedTherapistView();
  }

  /// Displayed when user is NOT linked with a doctor
  Widget _buildDoctorRequiredView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDEAE0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFD6F0EA),
                shape: BoxShape.circle,
              ),
              child: const Text('🩺', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 18),
            Text(
              'First You Need to Link with a Doctor',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You are not currently linked with a therapist. Please find and link with an approved doctor to receive personalized speech therapy, session appointments, and clinical tracking.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0ECE3)),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(Icons.check_circle_outline, 'Browse verified pediatric speech specialists'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(Icons.check_circle_outline, 'Book live 30-minute therapy appointments'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(Icons.check_circle_outline, 'Track phoneme pronunciation progress together'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38796D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
                  ).then((_) => _loadDoctorStatus());
                },
                icon: const Icon(Icons.search, color: Colors.white, size: 20),
                label: Text(
                  'Find & Link a Doctor',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF38796D), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Displayed when registration request is pending doctor's acceptance
  Widget _buildPendingApprovalView() {
    final docName = _pendingRequest?['doctor_name'] ?? _pendingRequest?['doctor_id'] ?? 'your selected speech therapist';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDEAE0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Text('⏳', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 18),
            Text(
              'Doctor Approval Pending',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your registration request has been submitted to $docName. As soon as the doctor accepts, your profile and appointments will appear here automatically with zero delay.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF38796D)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
                  ).then((_) => _loadDoctorStatus());
                },
                child: Text(
                  'Check Other Doctors / Status',
                  style: GoogleFonts.poppins(color: const Color(0xFF38796D), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displayed when doctor is linked and approved
  Widget _buildApprovedTherapistView() {
    final doctor = _doctor ?? {};

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFf3f0e9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEDEAE0)),
            ),
            child: Column(
              children: [
                const CircleAvatar(radius: 32, child: Text('🧑‍⚕️', style: TextStyle(fontSize: 28))),
                const SizedBox(height: 12),
                Text(
                  doctor['full_name'] ?? 'Doctor',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${doctor['qualification'] ?? 'Speech Specialist'} · ${doctor['years_of_experience'] ?? '?'} yrs experience',
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
                    '✓ Registered & Linked',
                    style: GoogleFonts.poppins(color: const Color(0xff2E6F65), fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFf3f0e9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDEAE0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: CupertinoColors.activeBlue),
                  title: Text('Languages', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(doctor['languages_spoken'] ?? 'English, Urdu', style: GoogleFonts.poppins(color: Colors.black54)),
                ),
                const Divider(height: 1, color: Colors.black26, thickness: 0.7),
                ListTile(
                  leading: const Icon(Icons.star, color: CupertinoColors.systemYellow),
                  title: Text('Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text('${doctor['rating'] ?? 'N/A'}', style: GoogleFonts.poppins(color: Colors.black54)),
                ),
                if (doctor['consultation_fee'] != null) ...[
                  const Divider(height: 1, color: Colors.black26, thickness: 0.7),
                  ListTile(
                    leading: const Icon(Icons.payments_outlined, color: Color(0xFF38796D)),
                    title: Text('Consultation Fee', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('PKR ${doctor['consultation_fee']} / session', style: GoogleFonts.poppins(color: Colors.black54)),
                  ),
                ],
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
                  MaterialPageRoute(builder: (context) => const SessionsScreen()),
                ).then((_) => _loadDoctorStatus());
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
                      patientName: _patientRow?['name'] ?? _patientRow?['child_name'] ?? 'Child',
                    ),
                  ),
                ).then((_) => _loadDoctorStatus());
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
              child: Text('Unregister from this Doctor', style: GoogleFonts.poppins(color: const Color(0xffC0432A), fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}