import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';

class LevelTile extends StatelessWidget {
  final PracticeLevel level;
  final int completionPercent;
  final VoidCallback onTap;
  final bool locked;

  const LevelTile({
    super.key,
    required this.level,
    required this.completionPercent,
    required this.onTap,
    this.locked = false,
  });

  IconData get _icon {
    switch (level) {
      case PracticeLevel.words:
        return Icons.text_fields_rounded;
      case PracticeLevel.sentences:
        return Icons.short_text_rounded;
      case PracticeLevel.fillBlanks:
        return Icons.rule_rounded;
      case PracticeLevel.poems:
        return Icons.menu_book_rounded;
      case PracticeLevel.story:
        return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    final complete = completionPercent >= 100;
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Color(0xFFf3f0e9),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: InkWell(
          onTap: locked
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                  backgroundColor: Color(0xFFf3f0e9),
                  content: Text('Complete the previous level first.', style: GoogleFonts.poppins(color: Colors.black),)),
            );
          }
              : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: completionPercent / 100,
                          strokeWidth: 3.5,
                          backgroundColor: AppColors.cardBorder,
                          color: complete ? AppColors.accentGreen : AppColors.accentGold,
                        ),
                      ),
                      Icon(
                        locked ? Icons.lock_outline : _icon,
                        size: 20,
                        color: complete ? AppColors.accentGreen : Colors.black,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: r.space(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: r.font(15), color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked ? 'Locked' : (complete ? 'Complete' : '$completionPercent% complete'),
                        style: GoogleFonts.poppins(fontSize: r.font(12), color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Icon(locked ? Icons.lock_outline : Icons.chevron_right_rounded, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }
}