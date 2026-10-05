import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/progress_controller.dart';
import '../../models/alphabet.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';
import '../widgets/level_tile.dart';
import 'words_screen.dart';
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
      extendBodyBehindAppBar: true,
      backgroundColor: Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize:  Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
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
              title: Text('Sound ${widget.alphabet.letter}', style: GoogleFonts.poppins(color: Colors.black),)),
        ),
      ),
      body: SafeArea(
        child: Consumer<ProgressController>(
          builder: (context, progress, _) {
            final progVal = progress.alphabetProgress;
            final overall = (progVal == progVal.roundToDouble())
                ? '${progVal.toInt()}'
                : progVal.toStringAsFixed(2);
        
            return Padding(
              padding: r.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(r.space(16)),
                    decoration: BoxDecoration(
                      // color: Color(0xFFf3f0e9),
                      color: Color(0xFFf3f0e9),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: r.speakerButtonRadius * 2,
                          height: r.speakerButtonRadius * 2,
                          decoration:  BoxDecoration(
                          ),
                          alignment: Alignment.center,
                          child: Text(widget.alphabet.letter,
                              style: GoogleFonts.gulzar(fontSize: r.font(22), fontWeight: FontWeight.w700, color: Colors.black)),
                        ),
                        SizedBox(width: r.space(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sound',
                                  style: GoogleFonts.poppins(fontSize: r.font(18), fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text('$overall% overall',
                                  style: GoogleFonts.poppins(color: AppColors.accentGold, fontWeight: FontWeight.w600, fontSize: r.font(13))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r.space(20)),
                  Text('PRACTICE LEVELS', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  SizedBox(height: r.space(10)),
                  Expanded(
                    child: ListView(
                      children: PracticeLevel.values.map((level) {
                        return LevelTile(
                          level: level,
                          completionPercent: progress.completion[level] ?? 0,
                          locked: !progress.isLevelUnlocked(level),
                          onTap: () => _openLevel(context, level),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: r.space(12)),
                  ElevatedButton(
                    onPressed: () => _openLevel(context, PracticeLevel.words),
                    child: Text('Continue with Words', style: GoogleFonts.poppins(fontSize: 17)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff38796D)
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
