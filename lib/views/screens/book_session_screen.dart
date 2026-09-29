import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/core_backend_service.dart';
import '../../auth/auth_service.dart';

class BookSessionScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String patientName;

  const BookSessionScreen({super.key, required this.doctor, required this.patientName});

  @override
  State<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  bool isLoading = false;
  bool isLoadingSlots = false;
  List<String> availableSlots = [];
  List<Map<String, dynamic>> allSlots = [];
  DateTime? selectedDate;
  String? selectedSlot;
  List<DateTime> next7Days = [];

  String get currentUid => AuthService.instance.currentUid ?? (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    next7Days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
    selectedDate = next7Days.first;
    fetchSlotsForDate(selectedDate!);
  }

  Future<void> fetchSlotsForDate(DateTime date) async {
    setState(() => isLoadingSlots = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final res = await CoreBackendService().getDoctorSlotsWithDetails(
        widget.doctor['id'].toString(),
        dateStr,
      );
      if (mounted) {
        final slots = (res['slots'] as List? ?? []).map((e) => e.toString()).toList();
        final rawAll = (res['all_slots'] as List? ?? []).cast<Map<String, dynamic>>();

        setState(() {
          availableSlots = slots;
          allSlots = rawAll;
          if (selectedSlot != null && !availableSlots.contains(selectedSlot)) {
            selectedSlot = null;
          }
          isLoadingSlots = false;
        });
      }
    } catch (e) {
      print('Error fetching slots: $e');
      if (mounted) {
        setState(() {
          availableSlots = [];
          allSlots = [];
          selectedSlot = null;
          isLoadingSlots = false;
        });
      }
    }
  }

  Widget buildSlots() {
    if (isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (allSlots.isEmpty && availableSlots.isEmpty) {
      return Text('No slots available on this day.', style: GoogleFonts.poppins(color: Colors.black45));
    }

    final slotsToDisplay = allSlots.isNotEmpty
        ? allSlots
        : availableSlots.map((s) => {'time': s, 'is_available': true, 'status': 'available'}).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slotsToDisplay.map((slotInfo) {
        final timeStr = slotInfo['time'] as String;
        final isAvailable = slotInfo['is_available'] == true;
        final isSelected = selectedSlot == timeStr;
        final status = slotInfo['status'] as String? ?? 'available';

        if (!isAvailable) {
          final isPast = status == 'past';
          final badgeText = isPast ? 'Past' : 'Booked';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD6D6D6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black38,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPast ? Colors.black12 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPast ? Colors.black45 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () => setState(() => selectedSlot = timeStr),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff38796D) : const Color(0xFFf3f0e9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xff38796D) : const Color(0xFFEDEAE0),
              ),
            ),
            child: Text(
              timeStr,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void showReviewSheet() {
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
            Text('Review Booking', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
             SizedBox(height: 16),
            Text('Doctor: ${widget.doctor['full_name']}', style: GoogleFonts.poppins()),
             SizedBox(height: 4),
            Text('Date: ${DateFormat('EEEE, MMMM d').format(selectedDate!)}', style: GoogleFonts.poppins()),
             SizedBox(height: 4),
            Text('Time: $selectedSlot', style: GoogleFonts.poppins()),
            SizedBox(height: 4),
            Text(
              'Rs. ${widget.doctor['consultation_fee']} / session',
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
            ),
             SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff38796D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: confirmBooking,
                child: Text('Confirm Booking', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmBooking() async {
    try {
      final startTime = DateFormat('h:mm a').parse(selectedSlot!);
      final endTime = startTime.add(const Duration(minutes: 30));

      final res = await CoreBackendService().bookAppointment(
        doctorId: widget.doctor['id'].toString(),
        appointmentDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
        startTime: DateFormat('HH:mm:ss').format(startTime),
        endTime: DateFormat('HH:mm:ss').format(endTime),
      );

      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        if (res['success'] == true) {
          Navigator.pop(context); // close booking screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xff38796D),
              content: Text(res['message'] ?? 'Appointment requested! Pending therapist confirmation.'),
            ),
          );
        } else {
          // If conflict or failed, refresh slots and clear selection
          setState(() => selectedSlot = null);
          if (selectedDate != null) {
            fetchSlotsForDate(selectedDate!);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade700,
              content: Text(res['message'] ?? 'Could not book session.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error booking session: $e');
      if (mounted) {
        Navigator.pop(context);
        setState(() => selectedSlot = null);
        if (selectedDate != null) {
          fetchSlotsForDate(selectedDate!);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Text('Something went wrong. Please choose an available slot.'),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize:  Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
            title: Text('Book Session', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFf3f0e9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDEAE0)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 24, child: Text('🩺')),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.doctor['full_name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text(
                        '${widget.doctor['qualification'] ?? ''} · ${widget.doctor['years_of_experience'] ?? '?'} yrs',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('SELECT DATE', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black, letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: next7Days.length,
                itemBuilder: (context, index) {
                  final date = next7Days[index];
                  final isSelected = selectedDate != null &&
                      date.year == selectedDate!.year &&
                      date.month == selectedDate!.month &&
                      date.day == selectedDate!.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                        selectedSlot = null;
                      });
                      fetchSlotsForDate(date);
                    },
                    child: Container(
                      width: 55,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xff38796D) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEDEAE0)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(date),
                            style: GoogleFonts.poppins(fontSize: 11, color: isSelected ? Colors.white70 : Colors.black54),
                          ),
                          Text(
                            DateFormat('d').format(date),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text('AVAILABLE TIME SLOTS', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black, letterSpacing: 1)),
            const SizedBox(height: 8),
            if (selectedDate == null)
              Text('Pick a date first', style: GoogleFonts.poppins(color: Colors.black))
            else
              buildSlots(),
            const SizedBox(height: 30),
            if (selectedDate != null && selectedSlot != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff38796D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: showReviewSheet,
                  child: Text('Book a session', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}