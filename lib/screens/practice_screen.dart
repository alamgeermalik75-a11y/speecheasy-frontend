import 'package:flutter/material.dart';
import '../services/scoring_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mic_button.dart';
import '../widgets/score_panel.dart';

class PracticeScreen extends StatefulWidget {
  final String displayText;
  final String targetText;
  final String? subtitle;
  final bool isFullWordMode;
  final bool embedded;

  const PracticeScreen({
    super.key,
    required this.displayText,
    required this.targetText,
    this.subtitle,
    required this.isFullWordMode,
    this.embedded = false,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final SpeechService _speech = SpeechService();

  bool ready = false;
  bool isListening = false;
  String recognizedText = "";
  ScoreResult? result;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _speech.init().then((err) {
      if (!mounted) return;
      setState(() {
        ready = err == null;
        errorMsg = err;
      });
    });
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  Future<void> _playReference() => _speech.speak(widget.targetText);

  Future<void> _startListening() async {
    if (!ready) return;
    setState(() {
      isListening = true;
      recognizedText = "";
      result = null;
      errorMsg = null;
    });
    final isLong = widget.targetText.length > 12;
    await _speech.listen(
      listenFor: Duration(seconds: isLong ? 20 : 10),
      pauseFor: Duration(seconds: isLong ? 5 : 3),
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => recognizedText = text);
        if (isFinal) _scoreResult();
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stopListening();
    if (!mounted) return;
    setState(() => isListening = false);
    if (recognizedText.isNotEmpty) _scoreResult();
  }

  void _scoreResult() {
    if (!mounted) return;
    final r = widget.isFullWordMode
        ? ScoringService.scoreFullWord(recognizedText, widget.targetText)
        : ScoringService.scoreFocusWords(recognizedText, widget.targetText);
    setState(() {
      isListening = false;
      result = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: EdgeInsets.all(widget.embedded ? 8 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.embedded) ...[
            Text(
              widget.displayText,
              style: TextStyle(
                fontSize: widget.displayText.length > 12 ? 26 : 52,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.subtitle!, style: const TextStyle(fontSize: 16, color: AppColors.inkMuted)),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _playReference,
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              label: const Text("صحیح آواز سنیں", textDirection: TextDirection.rtl),
            ),
            const SizedBox(height: 28),
          ],
          MicButton(
            isListening: isListening,
            enabled: ready,
            radius: widget.embedded ? 34 : 46,
            onTap: isListening ? _stopListening : _startListening,
          ),
          const SizedBox(height: 10),
          Text(
            isListening ? "سن رہا ہوں..." : "بولنے کے لیے دبائیں",
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            textDirection: TextDirection.rtl,
          ),
          if (recognizedText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF3EEE4), borderRadius: BorderRadius.circular(12)),
              child: Text(
                "سنائی دیا: $recognizedText",
                style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (errorMsg != null) ...[
            const SizedBox(height: 14),
            Text(errorMsg!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
          ],
          if (result != null) ...[
            const SizedBox(height: 22),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 14),
            ScorePanel(result: result!),
          ],
        ],
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text("مشق کریں")),
      body: SafeArea(child: body),
    );
  }
}
