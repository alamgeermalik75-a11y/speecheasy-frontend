import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final CategoryStyle style;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(style.icon, color: style.color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
