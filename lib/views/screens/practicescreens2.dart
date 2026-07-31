import 'package:flutter/material.dart';
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
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(r.space(20)),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(AppTheme.radius),
                                        border: Border.all(color: AppColors.cardBorder),
                                        boxShadow: AppTheme.cardShadow,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '${controller.index + 1} of ${controller.items.length}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: r.space(16)),
                                          Text(
                                            controller.current!.text,
                                            style: TextStyle(fontSize: r.font(26), fontWeight: FontWeight.w600),
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.center,
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
                                            controller.isSpeaking ? 'Tap to stop' : 'Tap to hear it',
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
