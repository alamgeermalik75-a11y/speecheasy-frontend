import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/practice_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../models/alphabet.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../widgets/error_state_view.dart';
import '../widgets/pronunciation_result_card.dart';

class PracticeScreen extends StatefulWidget {
  final Alphabet alphabet;
  final PracticeLevel level;

  const PracticeScreen({super.key, required this.alphabet, required this.level});

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<PracticeController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(title: Text('${widget.alphabet.letter} ${widget.level.label}')),
            body: controller.loading
                ? const Center(child: CircularProgressIndicator())
                : controller.loadError != null
                    ? ErrorStateView(
                        message: controller.loadError!,
                        onRetry: () => controller.loadFromApi(widget.alphabet, widget.level),
                      )
                    : controller.items.isEmpty
                        ? const Center(child: Text('No content available yet.'))
                        : SingleChildScrollView(
                            padding: r.pagePadding,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                                child: Column(
                                  children: [
                                    Text('${controller.index + 1} of ${controller.items.length}',
                                        style: const TextStyle(color: AppColors.textMuted)),
                                    SizedBox(height: r.space(16)),
                                    Text(
                                      controller.current!.text,
                                      style: TextStyle(fontSize: r.font(26)),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
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
                                    Text(controller.isSpeaking ? 'Tap to stop' : 'Tap to hear it',
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
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(fontSize: r.font(18))),
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
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(color: Colors.white))
                                          : const Text('Check pronunciation'),
                                    ),
                                    if (controller.result != null) _buildResultCard(r, controller),
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
            Expanded(child: OutlinedButton(onPressed: controller.retry, child: const Text('Try Again'))),
            const SizedBox(width: 12),
            if (controller.hasNext)
              Expanded(
                child: ElevatedButton(onPressed: controller.next, child: const Text('Next')),
              ),
          ],
        ),
      ],
    );
  }
}
