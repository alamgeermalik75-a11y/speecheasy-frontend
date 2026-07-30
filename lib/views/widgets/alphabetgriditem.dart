import 'package:flutter/material.dart';
import '../../models/alphabet.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';

class AlphabetGridItem extends StatelessWidget {
  final Alphabet alphabet;
  final VoidCallback onTap;

  final bool unresolved;

  final VoidCallback? onRetry;

  const AlphabetGridItem({
    super.key,
    required this.alphabet,
    required this.onTap,
    this.unresolved = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    return InkWell(
      onTap: unresolved ? onRetry : onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: unresolved ? AppColors.accentGold : AppColors.cardBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: EdgeInsets.symmetric(vertical: r.space(14)),
        child: unresolved
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, color: AppColors.accentGold, size: 22),
                  SizedBox(height: r.space(6)),
                  Text('Tap to retry', style: TextStyle(fontSize: r.font(11), color: AppColors.textMuted)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    alphabet.letter,
                    style: TextStyle(fontSize: r.font(30), fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                  SizedBox(height: r.space(6)),
                  Text(
                    alphabet.exampleWord,
                    style: TextStyle(fontSize: r.font(12), color: AppColors.textMuted),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
