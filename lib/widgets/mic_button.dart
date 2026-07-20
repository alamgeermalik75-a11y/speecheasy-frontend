import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MicButton extends StatelessWidget {
  final bool isListening;
  final bool enabled;
  final VoidCallback onTap;
  final double radius;

  const MicButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.enabled = true,
    this.radius = 44,
  });

  @override
  Widget build(BuildContext context) {
    final color = isListening ? AppColors.danger : AppColors.saffron;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: enabled ? color : AppColors.inkMuted.withOpacity(0.3),
          shape: BoxShape.circle,
          boxShadow: [
            if (enabled)
              BoxShadow(color: color.withOpacity(0.35), blurRadius: 18, spreadRadius: isListening ? 6 : 2),
          ],
        ),
        child: Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: radius * 0.75),
      ),
    );
  }
}
