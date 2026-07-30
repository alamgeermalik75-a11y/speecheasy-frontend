import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/fill_blank_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../models/alphabet.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../widgets/error_state_view.dart';
import '../widgets/pronunciation_result_card.dart';

class FillBlankScreen extends StatefulWidget {
  final Alphabet alphabet;
  const FillBlankScreen({super.key, required this.alphabet});

  @override
  State<FillBlankScreen> createState() => _FillBlankScreenState();
}

class _FillBlankScreenState extends State<FillBlankScreen> {
  late final FillBlankController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FillBlankController();
    _controller.loadFromApi(widget.alphabet);
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
      child: Consumer<FillBlankController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(title: Text('${widget.alphabet.letter} Fill in the blanks')),
            body: controller.loading
                ? const Center(child: CircularProgressIndicator())
                : controller.loadError != null
                    ? ErrorStateView(
                        message: controller.loadError!,
                        onRetry: () => controller.loadFromApi(widget.alphabet),
                      )
                    : controller.items.isEmpty
                        ? const Center(child: Text('No content available yet.'))
                        : SingleChildScrollView(
                            padding: r.pagePadding,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('${controller.index + 1} of ${controller.items.length}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: AppColors.textMuted)),
                                    SizedBox(height: r.space(16)),
                                    Text(
                                      controller.current!.question,
                                      style: TextStyle(fontSize: r.font(24), fontWeight: FontWeight.w600),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: r.space(20)),
                                    Text('Ek option chunein:',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: r.font(13))),
                                    SizedBox(height: r.space(10)),
                                    ...controller.current!.options.map((opt) {
                                      final selected = controller.selectedOption == opt;
                                      final checked = controller.result != null;
                                      final isCorrectAnswer = opt == controller.current!.answer;

                                      Color borderColor = selected ? AppColors.accentGreen : AppColors.cardBorder;
                                      Color? fillColor = selected ? AppColors.lightGreenBg : null;
                                      double borderWidth = selected ? 2 : 1;
                                      Widget? trailingIcon;

                                      if (checked) {
                                        if (isCorrectAnswer) {
                                          borderColor = AppColors.accentGreen;
                                          fillColor = AppColors.lightGreenBg;
                                          borderWidth = 2;
                                          trailingIcon = const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20);
                                        } else if (selected) {
                                          borderColor = AppColors.danger;
                                          fillColor = AppColors.lightDangerBg;
                                          borderWidth = 2;
                                          trailingIcon = const Icon(Icons.cancel, color: AppColors.danger, size: 20);
                                        } else {
                                          fillColor = null;
                                        }
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: OutlinedButton(

                                          onPressed: checked ? null : () => controller.selectOption(opt),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: fillColor,
                                            disabledBackgroundColor: fillColor,
                                            side: BorderSide(color: borderColor, width: borderWidth),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(opt,
                                                    textDirection: TextDirection.rtl,
                                                    style: TextStyle(fontSize: r.font(18))),
                                              ),
                                              if (trailingIcon != null) trailingIcon,
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    if (controller.selectedOption != null) ...[
                                      const Divider(height: 40),
                                      Text('Ab bolein:',
                                          style: TextStyle(color: AppColors.textMuted, fontSize: r.font(13)),
                                          textAlign: TextAlign.center),
                                      SizedBox(height: r.space(6)),
                                      Text(
                                        controller.selectedOption!,
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(fontSize: r.font(26), fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: r.space(10)),
                                      Center(
                                        child: IconButton(
                                          iconSize: 40,
                                          icon: CircleAvatar(
                                            radius: r.speakerButtonRadius,
                                            child: Icon(controller.isSpeaking ? Icons.stop : Icons.volume_up),
                                          ),
                                          onPressed: controller.playSelectedOption,
                                        ),
                                      ),
                                      SizedBox(height: r.space(10)),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () => controller.toggleMic(onError: _showMessage),
                                          child: CircleAvatar(
                                            radius: r.micButtonRadius,
                                            backgroundColor: controller.isRecording ? AppColors.danger : AppColors.primaryDark,
                                            child: Icon(controller.isRecording ? Icons.stop : Icons.mic,
                                                color: Colors.white, size: 28),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: r.space(8)),
                                      Text(
                                        controller.isRecording ? 'Listening... tap to stop' : 'Tap and speak',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: AppColors.textMuted),
                                      ),
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
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: r.font(18))),
                                        ),
                                      ],
                                      SizedBox(height: r.space(20)),
                                      ElevatedButton(
                                        onPressed: controller.isChecking
                                            ? null
                                            : () => controller.checkPronunciation(
                                                  onScored: (itemId, score) {
                                                    context.read<ProgressController>().recordAttempt(
                                                          itemId: itemId,
                                                          level: PracticeLevel.fillBlanks,
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

  Widget _buildResultCard(ResponsiveHelper r, FillBlankController controller) {
    final result = controller.result!;
    final passed = result.passed;
    final wrongOption = result.answerCorrect == false;
    final statusText = passed
        ? 'Nicely done'
        : (wrongOption ? 'Sahi jawab nahi tha' : 'Sahi bola nahi gaya');
    return Column(
      children: [
        SizedBox(height: r.space(20)),
        PronunciationResultCard(
          passed: passed,
          score: result.overallScore,
          statusText: statusText,
          subText: wrongOption ? 'Sahi jawab: ${controller.current!.answer}' : null,
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
