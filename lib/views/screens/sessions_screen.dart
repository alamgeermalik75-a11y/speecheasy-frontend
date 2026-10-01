import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/core_backend_service.dart';
import 'book_session_screen.dart';
import 'find_doctor_screen.dart';

enum DoctorLinkState { loading, notLinked, pending, approved, error }

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  DoctorLinkState _linkState = DoctorLinkState.loading;
  String? _errorMessage;
  List<Map<String, dynamic>> _appointments = [];
  int _cancellationCount = 0;
  bool _isRestricted = false;
  Map<String, dynamic>? _myDoctorInfo;
  Map<String, dynamic>? _pendingRequest;
  String _childName = 'Child';
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadSessionsData();
  }

  Future<void> _loadSessionsData() async {
    setState(() {
      _linkState = DoctorLinkState.loading;
      _errorMessage = null;
    });

    try {
      // 1. Fetch patient profile to get child name
      final profile = await CoreBackendService().getMyProfile();
      if (profile != null) {
        final c = profile['child_name']?.toString();
        if (c != null && c.isNotEmpty) {
          _childName = c;
        }
      }

      // 2. Fetch Doctor Status first from Railway Backend API
      final docStatus = await CoreBackendService().getMyDoctorStatus();
      if (!mounted) return;

      final statusStr = docStatus?['status'] ?? 'none';

      if (statusStr == 'approved') {
        _myDoctorInfo = docStatus?['doctor'] as Map<String, dynamic>?;
        _pendingRequest = null;

        // 3. Fetch Sessions from Railway Backend API
        final sessionData = await CoreBackendService().getMySessions();
        if (!mounted) return;

        if (sessionData != null) {
          final rawList = sessionData['appointments'] as List? ?? [];
          _appointments = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _cancellationCount = (sessionData['cancellation_count'] as num?)?.toInt() ?? 0;
          _isRestricted = sessionData['is_restricted'] == true;
        } else {
          _appointments = [];
          _cancellationCount = 0;
          _isRestricted = false;
        }
        _linkState = DoctorLinkState.approved;
      } else if (statusStr == 'pending') {
        _linkState = DoctorLinkState.pending;
        _pendingRequest = docStatus?['request'] as Map<String, dynamic>?;
        _myDoctorInfo = null;
        _appointments = [];
      } else {
        _linkState = DoctorLinkState.notLinked;
        _myDoctorInfo = null;
        _pendingRequest = null;
        _appointments = [];
      }
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Could not load sessions. Please check your connection.';
      _linkState = DoctorLinkState.error;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _handleCancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFBF9F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Appointment?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this session?',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'You have used $_cancellationCount of 5 permitted cancellations. Reaching 5 cancellations will lock new appointment bookings.',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFC0432A)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: GoogleFonts.poppins(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0432A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, Cancel', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      final res = await CoreBackendService().cancelAppointment(appointmentId);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF38796D),
            content: Text(
              res['message'] ?? 'Appointment cancelled.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
        await _loadSessionsData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              res['message'] ?? 'Failed to cancel appointment.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _navigateToBooking() {
    if (_isRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text(
            'Booking is restricted due to 5 cancellations. Please contact support.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (_myDoctorInfo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookSessionScreen(
            doctor: _myDoctorInfo!,
            patientName: _childName,
          ),
        ),
      ).then((_) => _loadSessionsData());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
      ).then((_) => _loadSessionsData());
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'booked':
        return const Color(0xFF38796D);
      case 'pending':
        return const Color(0xFFD97706);
      case 'completed':
        return const Color(0xFF2563EB);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDisplayDate(dynamic dateVal) {
    if (dateVal == null) return 'Date N/A';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return DateFormat('EEE, MMM d, yyyy').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  String _formatDisplayTime(dynamic timeVal) {
    if (timeVal == null) return '';
    final s = timeVal.toString().trim();
    try {
      if (s.contains(':')) {
        final parts = s.split(':');
        final hr = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final dt = DateTime(2000, 1, 1, hr, min);
        return DateFormat('h:mm a').format(dt);
      }
      return s;
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0x33BAB49B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            ),
          ),
        ),
        title: Text(
          'My Sessions',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF38796D)),
            tooltip: 'Refresh',
            onPressed: _linkState == DoctorLinkState.loading ? null : _loadSessionsData,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildBodyContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_linkState == DoctorLinkState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF38796D)),
      );
    }

    if (_linkState == DoctorLinkState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'An error occurred.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38796D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadSessionsData,
                child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // STATE: NOT LINKED WITH DOCTOR -> SHOW DIRECT LINK REQUIRED SCREEN
    if (_linkState == DoctorLinkState.notLinked) {
      return _buildDoctorRequiredView();
    }

    // STATE: DOCTOR APPROVAL PENDING
    if (_linkState == DoctorLinkState.pending) {
      return _buildPendingApprovalView();
    }

    // STATE: DOCTOR APPROVED -> SHOW SESSIONS LIST
    return RefreshIndicator(
      color: const Color(0xFF38796D),
      onRefresh: _loadSessionsData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linked Doctor Header Card
            _buildLinkedDoctorCard(),
            const SizedBox(height: 14),

            // Cancellation Quota Banner
            _buildQuotaBanner(),
            const SizedBox(height: 16),

            // Sessions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appointments (${_appointments.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRestricted ? Colors.grey : const Color(0xFF38796D),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _isRestricted ? null : _navigateToBooking,
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: Text(
                    'Book Session',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Empty State or List of Appointments
            if (_appointments.isEmpty)
              _buildEmptyAppointmentsView()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildAppointmentCard(_appointments[index]);
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Displayed when patient has no approved doctor and no pending request
  Widget _buildDoctorRequiredView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDEAE0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
              'Link with a Doctor First',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'To book and attend one-on-one therapy sessions, your child must first be linked with an approved SpeechEasy therapist.',
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
                  _buildBenefitRow(Icons.check_circle_outline, 'Personalized 30-min therapy scheduling'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(Icons.check_circle_outline, 'Direct clinical progress reviews by your doctor'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(Icons.check_circle_outline, 'Tailored articulation & speech guidance'),
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
                  ).then((_) => _loadSessionsData());
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

  /// Displayed when patient has a pending doctor request
  Widget _buildPendingApprovalView() {
    final docName = _pendingRequest?['doctor_name'] ?? _pendingRequest?['doctor_id'] ?? 'your selected speech therapist';

    return SingleChildScrollView(
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
              'Your registration request has been sent to $docName. Once accepted, your therapy session schedule will be unlocked right here.',
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
                  ).then((_) => _loadSessionsData());
                },
                child: Text(
                  'Check Request Status',
                  style: GoogleFonts.poppins(color: const Color(0xFF38796D), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedDoctorCard() {
    final doc = _myDoctorInfo ?? {};
    final docName = doc['full_name'] ?? 'Assigned Doctor';
    final qualification = doc['qualification'] ?? 'Speech Therapist';
    final fee = doc['consultation_fee'];
    final exp = doc['years_of_experience'];
    final rating = doc['rating'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF38796D),
            child: Text('🩺', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                Text(
                  exp != null ? '$qualification · $exp yrs exp' : qualification,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (fee != null)
                Text(
                  'PKR $fee',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF38796D), fontSize: 13),
                ),
              if (rating != null && (rating as num) > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaBanner() {
    if (_isRestricted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.block, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Restricted',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You have reached the maximum limit of 5 appointment cancellations. New bookings are currently locked.',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7F1D1D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7E1CD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF137333), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cancellations: $_cancellationCount / 5 used. Reaching 5 cancellations locks future appointment bookings.',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0D652D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointmentsView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📅', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          Text(
            'No Sessions Booked Yet',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick an available 30-minute slot with your speech therapist.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38796D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _isRestricted ? null : _navigateToBooking,
            child: Text(
              'Book Your First Session',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final appointmentId = appt['id']?.toString() ?? '';
    final status = (appt['status'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);
    final isCancelled = status.toLowerCase() == 'cancelled';
    final isCompleted = status.toLowerCase() == 'completed';
    final canCancel = !isCancelled && !isCompleted;

    final dateStr = _formatDisplayDate(appt['appointment_date']);
    final startTimeStr = _formatDisplayTime(appt['start_time']);
    final endTimeStr = _formatDisplayTime(appt['end_time']);
    final timeStr = '$startTimeStr - $endTimeStr';

    final patient = (appt['patient'] as Map?) ?? {};
    final childName = patient['child_name']?.toString() ?? _childName;
    final age = patient['age'];

    final doctor = (appt['doctor'] as Map?) ?? {};
    final doctorName = doctor['full_name']?.toString() ?? 'Speech Therapist';
    final qualification = doctor['qualification']?.toString();
    final fee = doctor['consultation_fee'];
    final rating = doctor['rating'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session #$appointmentId',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0ECE3)),
          const SizedBox(height: 12),

          // Date & Time Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF38796D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Doctor & Child Info Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFD6F0EA),
                      child: Text('🩺', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (qualification != null && qualification.isNotEmpty)
                            Text(
                              qualification,
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                    if (fee != null)
                      Text(
                        'PKR $fee',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF38796D),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFEDEAE0)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFFFE4D6),
                      child: Text('👶', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        age != null ? 'Patient: $childName ($age yrs)' : 'Patient: $childName',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    if (rating != null && (rating as num) > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            rating.toString(),
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cancel Action (if eligible)
          if (canCancel) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isCancelling ? null : () => _handleCancelAppointment(appointmentId),
                icon: const Icon(Icons.close, color: Color(0xFFDC2626), size: 14),
                label: Text(
                  'Cancel Session',
                  style: GoogleFonts.poppins(color: const Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
