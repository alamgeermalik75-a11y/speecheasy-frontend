import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../services/scoring_service.dart';
import '../theme/app_theme.dart';
import 'practice_screen.dart';

class ContentListScreen extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  final bool isFullWordMode;
  const ContentListScreen({super.key, required this.title, required this.items, required this.isFullWordMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final focusWords = isFullWordMode ? <String>[] : ScoringService.extractFocusWords(item.text);

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PracticeScreen(
                    displayText: item.text,
                    targetText: item.text,
                    subtitle: item.meaningEn,
                    isFullWordMode: isFullWordMode,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.text,
                            style: TextStyle(fontSize: isFullWordMode ? 26 : 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                            textDirection: TextDirection.rtl,
                          ),
                          if (item.meaningEn != null) ...[
                            const SizedBox(height: 3),
                            Text(item.meaningEn!, style: const TextStyle(color: AppColors.inkMuted, fontSize: 13)),
                          ] else if (focusWords.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: focusWords
                                  .map((w) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBEEDC),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(w, style: const TextStyle(fontSize: 12, color: AppColors.saffronDark), textDirection: TextDirection.rtl),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.mic_none_rounded, color: AppColors.inkMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
