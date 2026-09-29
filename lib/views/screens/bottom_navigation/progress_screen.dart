import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/core_backend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/auth_service.dart';

import 'bottom_navigation.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool isWeekly = true;
  bool isLoading = true;
  List<Map<String, dynamic>> attempts = [];

  String get currentUid => AuthService.instance.currentUid ?? (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    fetchAttempts();
  }

  Future<void> fetchAttempts() async {
    setState(() => isLoading = true);
    try {
      final data = await CoreBackendService().getAttemptHistory();

      if (mounted) {
        setState(() {
          attempts = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attempts: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }
  List<Map<String, dynamic>> getChartData() {
    if (attempts.isEmpty) return [];

    final now = DateTime.now();
    final Map<String, List<int>> grouped = {};
    final List<String> orderedKeys = [];

    if (isWeekly) {
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final key = '${day.day}/${day.month}';
        grouped[key] = [];
        orderedKeys.add(key);
      }
      for (final a in attempts) {
        final date = DateTime.parse(a['attempted_at']);
        final key = '${date.day}/${date.month}';
        if (grouped.containsKey(key)) {
          grouped[key]!.add(a['score'] as int);
        }
      }
    } else {
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: i * 7));
        final key = 'Wk ${4 - i}';
        grouped[key] = [];
        orderedKeys.add(key);
      }
      for (final a in attempts) {
        final date = DateTime.parse(a['attempted_at']);
        final daysAgo = now.difference(date).inDays;
        final weekIndex = (daysAgo / 7).floor();
        if (weekIndex >= 0 && weekIndex < 4) {
          final key = 'Wk ${4 - weekIndex}';
          grouped[key]?.add(a['score'] as int);
        }
      }
    }

    return orderedKeys.map((key) {
      final scores = grouped[key] ?? [];
      final avg = scores.isEmpty ? 0 : (scores.reduce((a, b) => a + b) / scores.length).round();
      return {'label': key, 'avg': avg};
    }).toList();
  }

  Widget buildToggleButton(String label, bool weeklyValue) {
    final selected = isWeekly == weeklyValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isWeekly = weeklyValue),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget buildChart() {
    final data = getChartData();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((d) {
        final avg = d['avg'] as int;
        final barHeight = (avg / 100) * 200;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('$avg%', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: barHeight < 4 ? 4 : barHeight.toDouble(),
              decoration: BoxDecoration(
                color: const Color(0xff38796D),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(d['label'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
          ],
        );
      }).toList(),
    );
  }
  Widget buildAchievements() {
    final unlocked = getAchievements();
    final items = [
      {'emoji': '🏆', 'label': '7-Day Streak', 'key': '7-Day Streak'},
      {'emoji': '🎯', 'label': 'First Mastered', 'key': 'First Mastered'},
    ];

    return Row(
      children: items.map((item) {
        final isUnlocked = unlocked[item['key']] ?? false;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDEAE0)),
            ),
            child: Opacity(
              opacity: isUnlocked ? 1.0 : 0.4,
              child: Column(
                children: [
                  Text(item['emoji']!, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    item['label']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  Map<String, bool> getAchievements() {
    final now = DateTime.now();
    bool sevenDayStreak = true;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final hasAttempt = attempts.any((a) {
        final date = DateTime.parse(a['attempted_at']);
        return date.year == day.year && date.month == day.month && date.day == day.day;
      });
      if (!hasAttempt) {
        sevenDayStreak = false;
        break;
      }
    }

    final firstMastered = attempts.any((a) => (a['score'] as int) >= 70);

    return {
      '7-Day Streak': sevenDayStreak,
      'First Mastered': firstMastered,
    };
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
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> BottomNavigation()));
                },
                child: Container(
                  child:  Icon(
                    Icons.keyboard_backspace_sharp,
                    color: Colors.black,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFBAB49B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            title: Text('Progress', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
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
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E4DA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  buildToggleButton('Weekly', true),
                  buildToggleButton('Monthly', false),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              isWeekly ? 'Last 7 Days' : 'Last 4 Weeks',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFE8E4DA),
                borderRadius: BorderRadius.circular(18)
              ),
              child: SizedBox(
                height: 260,
                child: attempts.isEmpty
                    ? Center(
                  child: Text(
                    'No practice sessions yet.\nStart practicing to see progress!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.black45),
                  ),
                )
                    : buildChart(),
              ),
            ),
             SizedBox(height: 30),
            Text(
              'ACHIEVEMENTS',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black54,
                letterSpacing: 1,
                fontWeight: FontWeight.bold
              ),
            ),
             SizedBox(height: 10),
            buildAchievements(),
          ],
        ),
      ),
    );
  }
}