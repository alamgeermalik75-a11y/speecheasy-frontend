import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/progress_controller.dart';
import '../../models/alphabet.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';
import '../widgets/level_tile.dart';
import 'wordsscreens5.dart';
import 'practicescreens2.dart';
import 'fillblankscreens6.dart';

class SoundDetailScreen extends StatefulWidget {
  final Alphabet alphabet;
  const SoundDetailScreen({super.key, required this.alphabet});

  @override
  State<SoundDetailScreen> createState() => _SoundDetailScreenState();
}

class _SoundDetailScreenState extends State<SoundDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressController>().loadForAlphabet(widget.alphabet.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.alphabet.letter} Sound')),
      body: Consumer<ProgressController>(
        builder: (context, progress, _) {
          final overall = progress.completion.values.isEmpty
              ? 0
              : (progress.completion.values.reduce((a, b) => a + b) / progress.completion.length).round();

          return Padding(
            padding: r.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.space(16)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: r.speakerButtonRadius * 2,
                        height: r.speakerButtonRadius * 2,
                        decoration: const BoxDecoration(
                          color: AppColors.lightGoldBg,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.alphabet.letter,
                            style: TextStyle(fontSize: r.font(22), fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                      ),
                      SizedBox(width: r.space(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${widget.alphabet.letter} sound',
                                style: TextStyle(fontSize: r.font(18), fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('$overall% overall',
                                style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w600, fontSize: r.font(13))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.space(20)),
                Text('PRACTICE LEVELS', style: Theme.of(context).textTheme.labelSmall),
                SizedBox(height: r.space(10)),
                Expanded(
                  child: ListView(
                    children: PracticeLevel.values.map((level) {
                      return LevelTile(
                        level: level,
                        completionPercent: progress.completion[level] ?? 0,
                        onTap: () => _openLevel(context, level),
                      );
                    }).toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openLevel(context, PracticeLevel.words),
                  child: const Text('Continue with Words'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openLevel(BuildContext context, PracticeLevel level) {
    if (level == PracticeLevel.words) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WordsScreen(alphabet: widget.alphabet)),
      );
    } else if (level == PracticeLevel.fillBlanks) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FillBlankScreen(alphabet: widget.alphabet)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeScreen(alphabet: widget.alphabet, level: level),
        ),
      );
    }
  }
}
