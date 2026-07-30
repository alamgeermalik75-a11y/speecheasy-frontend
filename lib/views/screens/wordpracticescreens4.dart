import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/practice_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../models/alphabet.dart';
import '../../models/word_item.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
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
            appBar: AppBar(
              title: Text(current?.position?.label ?? widget.level.label),
            ),
            body: current == null
                ? const Center(child: Text('No words available.'))
                : SingleChildScrollView(
                    padding: r.pagePadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                        child: Column(
                          children: [
                            Text('Word ${controller.index + 1} of ${controller.items.length}',
                                style: const TextStyle(color: AppColors.textMuted)),
                            SizedBox(height: r.space(24)),
                            Text(
                              current.text,
                              style: TextStyle(fontSize: r.font(42), fontWeight: FontWeight.w600),
                              textDirection: TextDirection.rtl,
                            ),
                            SizedBox(height: r.space(16)),
                            IconButton(
                              iconSize: 40,
                              icon: CircleAvatar(
                                radius: r.speakerButtonRadius,
                                child: Icon(controller.isSpeaking ? Icons.stop : Icons.volume_up),
                              ),
                              onPressed: controller.playReference,
                            ),
                            Text(controller.isSpeaking ? 'Tap to stop' : 'Tap to hear the word',
                                style: const TextStyle(color: AppColors.textMuted)),
                            const Divider(height: 40),
                            const Text('Now say it yourself', style: TextStyle(color: AppColors.textMuted)),
                            SizedBox(height: r.space(10)),
                            GestureDetector(
                              onTap: () => controller.toggleMic(onError: _showMessage),
                              child: CircleAvatar(
                                radius: r.micButtonRadius,
                                backgroundColor: controller.isRecording ? AppColors.danger : AppColors.primaryDark,
                                child: Icon(controller.isRecording ? Icons.stop : Icons.mic,
                                    color: Colors.white, size: 28),
                              ),
                            ),
                            SizedBox(height: r.space(8)),
                            Text(controller.isRecording ? 'Listening... tap to stop' : 'Tap and speak',
                                style: const TextStyle(color: AppColors.textMuted)),
                            if (controller.liveText.isNotEmpty) ...[
                              SizedBox(height: r.space(12)),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(controller.liveText,
                                    textDirection: TextDirection.rtl, style: TextStyle(fontSize: r.font(18))),
                              ),
                            ],
                            SizedBox(height: r.space(20)),
                            ElevatedButton(
                              onPressed: controller.isChecking
                                  ? null
                                  : () => controller.checkPronunciation(
                                        level: widget.level,
                                        targetLetter: widget.alphabet.letter,
                                        onScored: (itemId, score) {
                                          context.read<ProgressController>().recordAttempt(
                                                itemId: itemId,
                                                level: widget.level,
                                                score: score,
                                              );
                                        },
                                        onInfo: _showMessage,
                                      ),
                              child: controller.isChecking
                                  ? const SizedBox(
                                      height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                  : const Text('Check pronunciation'),
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
          statusText: passed ? 'Nicely done' : 'Try again',
        ),
        SizedBox(height: r.space(20)),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: controller.retry, child: const Text('Try Again'))),
            const SizedBox(width: 12),
            if (controller.hasNext)
              Expanded(
                child: ElevatedButton(onPressed: controller.next, child: const Text('Next Word')),
              ),
          ],
        ),
      ],
    );
  }
}
