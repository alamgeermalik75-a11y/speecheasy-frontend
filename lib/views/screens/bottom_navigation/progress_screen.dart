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
  Map<String, dynamic>? overview;
  double overallProgress = 0.0;
  String currentAlphabet = '';
  double currentAlphabetProgress = 0.0;
  double dailyProgress = 0.0;
  double weeklyProgress = 0.0;
  double monthlyProgress = 0.0;

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
      final ov = await CoreBackendService().getProgressOverview();

      if (mounted) {
        setState(() {
          attempts = List<Map<String, dynamic>>.from(data);
          overview = ov;
          if (ov != null) {
            overallProgress = (ov['overall_progress'] as num?)?.toDouble() ?? 0.0;
            currentAlphabet = ov['alphabet_name']?.toString() ?? '';
            currentAlphabetProgress = (ov['alphabet_progress'] as num?)?.toDouble() ?? 0.0;
            dailyProgress = (ov['daily_progress'] as num?)?.toDouble() ?? 0.0;
            weeklyProgress = (ov['weekly_progress'] as num?)?.toDouble() ?? 0.0;
            monthlyProgress = (ov['monthly_progress'] as num?)?.toDouble() ?? 0.0;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attempts: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> getChartData() {
    final now = DateTime.now();

    // 1. Backend source of truth: use daily_history or weekly_history if provided
    if (overview != null) {
      if (isWeekly && overview!['daily_history'] is List && (overview!['daily_history'] as List).isNotEmpty) {
        final list = overview!['daily_history'] as List;
        return list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final prog = (m['progress'] as num?)?.toDouble() ?? 0.0;
          return {
            'label': m['label']?.toString() ?? '',
            'val': prog,
          };
        }).toList();
      } else if (!isWeekly && overview!['weekly_history'] is List && (overview!['weekly_history'] as List).isNotEmpty) {
        final list = overview!['weekly_history'] as List;
        return list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final prog = (m['progress'] as num?)?.toDouble() ?? 0.0;
          return {
            'label': m['label']?.toString() ?? '',
            'val': prog,
          };
        }).toList();
      }
    }

    // 2. Fallback when overview is not yet loaded: return 7 zero days / 4 zero weeks
    if (isWeekly) {
      final List<Map<String, dynamic>> fallback = [];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        fallback.add({'label': '${day.day}/${day.month}', 'val': 0.0});
      }
      return fallback;
    } else {
      final List<Map<String, dynamic>> fallback = [];
      for (int i = 3; i >= 0; i--) {
        fallback.add({'label': 'Wk ${4 - i}', 'val': 0.0});
      }
      return fallback;
    }
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
    if (data.isEmpty) return const SizedBox(height: 120);

    final maxVal = data.fold<double>(0.0, (prev, e) {
      final v = (e['val'] as num?)?.toDouble() ?? 0.0;
      return v > prev ? v : prev;
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((d) {
        final val = (d['val'] as num?)?.toDouble() ?? 0.0;
        final barHeight = maxVal > 0 ? ((val / maxVal) * 140.0) : 4.0;
        final displayHeight = barHeight < 4.0 ? 4.0 : barHeight;

        String textLabel = '0%';
        if (val > 0) {
          textLabel = val >= 1.0 ? '${val.toStringAsFixed(1)}%' : '${val.toStringAsFixed(2)}%';
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(textLabel, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: displayHeight,
              decoration: BoxDecoration(
                color: const Color(0xff38796D),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(d['label']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
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
        final rawDate = a['attempted_at'] ?? a['created_at'];
        if (rawDate == null) return false;
        final date = DateTime.tryParse(rawDate.toString());
        if (date == null) return false;
        return date.year == day.year && date.month == day.month && date.day == day.day;
      });
      if (!hasAttempt) {
        sevenDayStreak = false;
        break;
      }
    }

    final firstMastered = attempts.any((a) {
      final score = (a['score'] as num?)?.toInt() ?? 0;
      return score >= 70;
    });

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
        preferredSize: const Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BottomNavigation()));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFBAB49B).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_backspace_sharp,
                    color: Colors.black,
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Progress & Focus Alphabet Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E4DA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overall Progress',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            Text(
                              '${overallProgress.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xff38796D)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (overallProgress / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.white60,
                            color: const Color(0xff38796D),
                            minHeight: 10,
                          ),
                        ),
                        if (currentAlphabet.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Sound: $currentAlphabet',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${currentAlphabetProgress.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xff38796D), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Toggle Button Weekly / Monthly
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
                  const SizedBox(height: 24),
                  Text(
                    isWeekly ? 'Last 7 Days' : 'Last 4 Weeks',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E4DA),
                      borderRadius: BorderRadius.circular(18),
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
                  const SizedBox(height: 30),
                  Text(
                    'ACHIEVEMENTS',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  buildAchievements(),
                ],
              ),
            ),
    );
  }
}