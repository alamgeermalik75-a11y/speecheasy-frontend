import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../theme/app_theme.dart';
import 'practice_screen.dart';

class FillBlankScreen extends StatefulWidget {
  final FillBlankItem item;
  const FillBlankScreen({super.key, required this.item});

  @override
  State<FillBlankScreen> createState() => _FillBlankScreenState();
}

class _FillBlankScreenState extends State<FillBlankScreen> {
  String? chosen;
  bool? isCorrect;

  void _choose(String option) {
    setState(() {
      chosen = option;
      isCorrect = option == widget.item.answer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displaySentence = chosen == null ? widget.item.template : widget.item.template.replaceAll("______", "【$chosen】");

    return Scaffold(
      appBar: AppBar(title: const Text("خالی جگہ پُر کریں")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
                child: Text(displaySentence, style: const TextStyle(fontSize: 22, color: AppColors.ink), textDirection: TextDirection.rtl, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 28),
              if (isCorrect != true)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.item.options.map((opt) {
                    final wasWrong = chosen == opt && isCorrect == false;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ElevatedButton(
                          onPressed: () => _choose(opt),
                          style: wasWrong
                              ? ElevatedButton.styleFrom(backgroundColor: AppColors.dangerBg, foregroundColor: AppColors.danger)
                              : null,
                          child: Text(opt, style: const TextStyle(fontSize: 18), textDirection: TextDirection.rtl),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (isCorrect == false)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text("یہ صحیح نہیں ہے، دوبارہ کوشش کریں۔", style: TextStyle(color: AppColors.danger), textDirection: TextDirection.rtl, textAlign: TextAlign.center),
                ),
              if (isCorrect == true) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                    SizedBox(width: 8),
                    Text("درست جواب! اب پورا جملہ بولیں", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700), textDirection: TextDirection.rtl),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PracticeScreen(
                    displayText: widget.item.fullText,
                    targetText: widget.item.fullText,
                    isFullWordMode: false,
                    embedded: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
