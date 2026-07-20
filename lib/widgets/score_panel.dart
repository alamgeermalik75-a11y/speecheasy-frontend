import 'package:flutter/material.dart';
import '../services/scoring_service.dart';
import '../theme/app_theme.dart';

Color _scoreColor(int score) {
  if (score >= 80) return AppColors.success;
  if (score >= 50) return AppColors.warning;
  return AppColors.danger;
}

Color _scoreBg(int score) {
  if (score >= 80) return AppColors.successBg;
  if (score >= 50) return AppColors.warningBg;
  return AppColors.dangerBg;
}

class ScorePanel extends StatelessWidget {
  final ScoreResult result;
  const ScorePanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result.score);
    final bg = _scoreBg(result.score);

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${result.score}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
              const Text("/100", style: TextStyle(fontSize: 11, color: AppColors.inkMuted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          ScoringService.feedbackFor(result.score),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
          textAlign: TextAlign.center,
        ),
        if (result.breakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text("پ/پھ لفظوں کا نتیجہ", style: TextStyle(fontSize: 12, color: AppColors.inkMuted), textDirection: TextDirection.rtl),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: result.breakdown.map((w) {
              final c = _scoreColor(w.score);
              final b = _scoreBg(w.score);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.4))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(w.word, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 15), textDirection: TextDirection.rtl),
                    const SizedBox(width: 6),
                    Text("${w.score}", style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
