import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/practice_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../models/alphabet.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';
import '../widgets/error_state_view.dart';
import '../widgets/mic_recorder_section.dart';
import '../widgets/pronunciation_result_card.dart';

class PracticeScreen extends StatefulWidget {
  final Alphabet alphabet;
  final PracticeLevel level;

  const PracticeScreen({
    super.key,
    required this.alphabet,
    required this.level,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PracticeController();
    _controller.loadFromApi(widget.alphabet, widget.level);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        backgroundColor: Color(0xFFf3f0e9),
        content: Text(message, style: GoogleFonts.poppins(color: Colors.black),)));
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<PracticeController>(
        builder: (context, controller, _) {
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
                      onTap: () {
                        Navigator.pop(context);
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
                  title: Text(
                    '${widget.level.label} ${widget.alphabet.letter} ',
                    style: GoogleFonts.poppins(color: Colors.black),
                  ),
                ),
              ),
            ),
            body: controller.loading
                ? const Center(child: CircularProgressIndicator())
                : controller.loadError != null
                ? ErrorStateView(
                    message: controller.loadError!,
                    onRetry: () =>
                        controller.loadFromApi(widget.alphabet, widget.level),
                  )
                : controller.items.isEmpty
                ? const Center(child: Text('No content available yet.'))
                : SingleChildScrollView(
                    padding: r.pagePadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: r.maxContentWidth,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${controller.index + 1} of ${controller.items.length}',
                              style: GoogleFonts.poppins(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: r.space(40)),
                            Text(
                              controller.current!.text,
                              style: GoogleFonts.gulzar(
                                fontSize: r.font(26),
                                fontWeight: FontWeight.w600,
                                wordSpacing: 3,
                                height: 2
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: r.space(12)),
                            IconButton(
                              iconSize: 40,
                              icon: CircleAvatar(
                                backgroundColor: Color(0xff38796D),
                                radius: r.speakerButtonRadius,
                                child: Icon(
                                  controller.isSpeaking
                                      ? Icons.stop
                                      : Icons.volume_up,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              onPressed: controller.playReference,
                            ),
                            Text(
                              controller.isSpeaking
                                  ? 'Tap to stop'
                                  : 'Tap to hear it',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12.5,
                              ),
                            ),
                            SizedBox(height: 40),
                            MicRecorderSection(
                              isRecording: controller.isRecording,
                              isChecking: controller.isChecking,
                              liveText: controller.liveText,
                              onMicTap: () async {
                                if (controller.isRecording) {
                                  await controller.toggleMic(
                                    onError: _showMessage,
                                  );
                                  await controller.checkPronunciation(
                                    level: widget.level,
                                    targetLetter: widget.alphabet.letter,
                                    onScored: (itemId, score) {
                                      context
                                          .read<ProgressController>()
                                          .recordAttempt(
                                            itemId: itemId,
                                            level: widget.level,
                                            score: score,
                                          );
                                    },
                                    onInfo: _showMessage,
                                  );
                                } else {
                                  await controller.toggleMic(
                                    onError: _showMessage,
                                  );
                                }
                              },
                            ),
                            if (controller.result != null)
                              _buildResultCard(r, controller),
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

  Widget _buildResultCard(ResponsiveHelper r, PracticeController controller) {
    final result = controller.result!;
    final passed = result.passed;
    return Column(
      children: [
        SizedBox(height: r.space(20)),
        PronunciationResultCard(
          passed: passed,
          score: result.overallScore,
          statusText: passed ? 'Nicely done' : 'Try again',
        ),
        SizedBox(height: r.space(20)),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.retry,
                child:  Text('Try Again', style: GoogleFonts.poppins(),),
              ),
            ),
            const SizedBox(width: 12),
            if (controller.hasNext)
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff38796D)
                  ),
                  onPressed: controller.next,
                  child:  Text('Next', style: GoogleFonts.poppins(fontSize: 18),),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
