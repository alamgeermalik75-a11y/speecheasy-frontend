import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../theme/app_theme.dart';
import 'fill_blank_screen.dart';

class FillBlankListScreen extends StatelessWidget {
  final List<FillBlankItem> items;
  const FillBlankListScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fill in the Blanks")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final f = items[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FillBlankScreen(item: f))),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(f.template, style: const TextStyle(fontSize: 17, color: AppColors.ink), textDirection: TextDirection.rtl),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
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
