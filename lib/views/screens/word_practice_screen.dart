import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/practice_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../models/alphabet.dart';
import '../../models/word_item.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';
import '../widgets/mic_recorder_section.dart';
import '../widgets/pronunciation_result_card.dart';

class WordPracticeScreen extends StatefulWidget {
  final Alphabet alphabet;
  final List<WordItem> words;
  final int startIndex;
  final PracticeLevel level;

  const WordPracticeScreen({
    super.key,
    required this.alphabet,
    required this.words,
    required this.startIndex,
    required this.level,
  });

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  late final PracticeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PracticeController();
    _controller.setItems(widget.words, startIndex: widget.startIndex);
    _controller.initSpeech().then((warning) {
      if (warning != null && mounted) _showMessage(warning);
    });
  }

  @override
  void dispose() {
    _controller.disposeControllers();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<PracticeController>(
        builder: (context, controller, _) {
          final current = controller.current;
          return Scaffold(
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
                  // title: Text(current?.position?.label ?? widget.level.label, style: GoogleFonts.poppins(color: Colors.black),),
                ),
              ),
            ),
            body: current == null
                ? Center(
                    child: Text(
                      'No words available.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  )
                : SingleChildScrollView(
                    padding: r.pagePadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                  Text(
                                    'Word ${controller.index + 1} of ${controller.items.length}',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textMuted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 60,),
                                  Text(
                                    current.text,
                                    style: GoogleFonts.gulzar(fontSize: r.font(42), fontWeight: FontWeight.w700),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  SizedBox(height: r.space(12)),
                                  IconButton(
                                    iconSize: 40,
                                    icon: CircleAvatar(
                                      backgroundColor: Color(0xff38796D),
                                      radius: r.speakerButtonRadius,
                                      child: Icon(controller.isSpeaking ? Icons.stop : Icons.volume_up, color: Colors.white, size: 25,),
                                    ),
                                    onPressed: controller.playReference,
                                  ),
                                  Text(
                                    controller.isSpeaking ? 'Tap to stop' : 'Tap to hear the word',
                                    style: GoogleFonts.poppins(color: Colors.black, fontSize: 12.5),
                                  ),

                             SizedBox(height: 50,),
                            MicRecorderSection(
                              isRecording: controller.isRecording,
                              isChecking: controller.isChecking,
                              liveText: controller.liveText,
                              onMicTap: () async {
                                if (controller.isRecording) {
                                  await controller.toggleMic(onError: _showMessage);
                                  await controller.checkPronunciation(
                                    level: widget.level,
                                    targetLetter: widget.alphabet.letter,
                                    onScored: (itemId, score) {
                                      context.read<ProgressController>().recordAttempt(
                                            itemId: itemId,
                                            level: widget.level,
                                            score: score,
                                            alphabetName: widget.alphabet.name,
                                          );
                                    },
                                    onInfo: _showMessage,
                                  );
                                } else {
                                  await controller.toggleMic(onError: _showMessage);
                                }
                              },
                            ),
                            if (controller.result != null) _buildResultCard(context, r, controller),
                          ],
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ResponsiveHelper r, PracticeController controller) {
    final result = controller.result!;
    final passed = result.passed;
    return Column(
      children: [
        SizedBox(height: r.space(20)),
        PronunciationResultCard(
          passed: passed,
          score: result.overallScore,
          statusText: passed ? 'Nicely done' : 'Try again'
        ),
        SizedBox(height: r.space(20)),
        Row(
          children: [
            Expanded(child: OutlinedButton(

                onPressed: controller.retry, child:  Text('Try Again',style: GoogleFonts.poppins(),))),
            const SizedBox(width: 12),
            if (controller.hasNext)
              Expanded(
                child: ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff38796D)
                    ),
                    onPressed: controller.next, child: Text('Next Word', style: GoogleFonts.poppins(),)),
              ),
          ],
        ),
      ],
    );
  }
}
