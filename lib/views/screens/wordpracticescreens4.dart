import 'package:flutter/material.dart';
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
            appBar: AppBar(
              title: Text(current?.position?.label ?? widget.level.label),
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
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(r.space(24)),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppTheme.radius),
                                border: Border.all(color: AppColors.cardBorder),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Word ${controller.index + 1} of ${controller.items.length}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: r.space(20)),
                                  Text(
                                    current.text,
                                    style: TextStyle(fontSize: r.font(42), fontWeight: FontWeight.w700),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  SizedBox(height: r.space(12)),
                                  IconButton(
                                    iconSize: 40,
                                    icon: CircleAvatar(
                                      radius: r.speakerButtonRadius,
                                      child: Icon(controller.isSpeaking ? Icons.stop : Icons.volume_up),
                                    ),
                                    onPressed: controller.playReference,
                                  ),
                                  Text(
                                    controller.isSpeaking ? 'Tap to stop' : 'Tap to hear the word',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 40),
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
