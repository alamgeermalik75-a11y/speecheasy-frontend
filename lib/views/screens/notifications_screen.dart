import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/core_backend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  String get currentUid => AuthService.instance.currentUid ?? (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    markAllAsRead();
  }

  Future<void> fetchNotifications() async {
    try {
      final list = await CoreBackendService().getNotifications();
      if (mounted) {
        setState(() {
          notifications = list;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await CoreBackendService().markNotificationsRead();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final ok = await CoreBackendService().clearNotifications();
      if (ok && mounted) {
        setState(() => notifications = []);
      }
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  String formatTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
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
            title: Text('Notifications', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
            actions: [
              TextButton(
                onPressed: clearAll,
                child: Text('Clear All', style: GoogleFonts.poppins(color: const Color(0xff38796D))),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
        child: Text(
          'No notifications yet.',
          style: GoogleFonts.poppins(color: Colors.black45),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                Text(n['icon'] ?? '🔔', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['message'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(formatTime(n['created_at']), style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}