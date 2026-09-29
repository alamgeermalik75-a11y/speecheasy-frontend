import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class PronunciationResultCard extends StatelessWidget {
  final bool passed;
  final int score;
  final String statusText;

  final String? subText;

  const PronunciationResultCard({
    super.key,
    required this.passed,
    required this.score,
    required this.statusText,
    this.subText,
  });

  @override
  Widget build(BuildContext context) {
    final tint = passed ? AppColors.accentGreen : AppColors.danger;
    final bg = passed ? AppColors.lightGreenBg : AppColors.lightDangerBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: bg, width: 1.4),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 5,
                    backgroundColor: bg,
                    color: tint,
                  ),
                ),
                Text('$score%', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: tint)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded, color: Color(0xff38796D), size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        statusText,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                if (subText != null) ...[
                  const SizedBox(height: 4),
                  Text(subText!,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
