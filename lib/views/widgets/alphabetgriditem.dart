import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          // color: Color(0xFFE3E1D2).withOpacity(0.6),
          color: Color(0xFFf3f0e9),
          borderRadius: BorderRadius.circular(25),
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
                  Text('Tap to retry', style: GoogleFonts.poppins(fontSize: r.font(11), color: AppColors.textMuted)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    alphabet.letter,
                    style: GoogleFonts.gulzar(fontSize: r.font(28), fontWeight: FontWeight.w500, color: Colors.black,),
                  ),
                ],
              ),
      ),
    );
  }
}
