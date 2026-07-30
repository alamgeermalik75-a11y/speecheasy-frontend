import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';

class LevelTile extends StatelessWidget {
  final PracticeLevel level;
  final int completionPercent;
  final VoidCallback onTap;

  const LevelTile({
    super.key,
    required this.level,
    required this.completionPercent,
    required this.onTap,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: onTap,
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
                    Icon(_icon, size: 18, color: complete ? AppColors.accentGreen : AppColors.primaryDark),
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
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: r.font(15), color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      complete ? 'Complete' : '$completionPercent% complete',
                      style: TextStyle(fontSize: r.font(12), color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
