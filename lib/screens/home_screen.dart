import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import 'content_list_screen.dart';
import 'fill_blank_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  AppContent? content;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final c = await _api.fetchContent();
      setState(() {
        content = c;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Server se connect nahi ho saka. Backend chal raha hai?\n($e)";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تلفظ سیکھیں"),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.saffron))
            : error != null
                ? _ErrorState(message: error!, onRetry: _load)
                : _CategoryList(content: content!),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.inkMuted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkMuted)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text("Dobara Koshish Karein")),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final AppContent content;
  const _CategoryList({required this.content});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          "پ/پھ کی مشق",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 4),
        const Text("Category chunein aur mushq shuru karein", style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
        const SizedBox(height: 20),
        CategoryCard(
          title: "Words",
          subtitle: "${content.words.length} lafz — poora lafz bolna",
          style: kCategoryStyles["words"]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentListScreen(title: "Words", items: content.words, isFullWordMode: true)),
          ),
        ),
        const SizedBox(height: 12),
        CategoryCard(
          title: "Sentences",
          subtitle: "${content.sentences.length} jumle",
          style: kCategoryStyles["sentences"]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentListScreen(title: "Sentences", items: content.sentences, isFullWordMode: false)),
          ),
        ),
        const SizedBox(height: 12),
        CategoryCard(
          title: "Poem",
          subtitle: "${content.poem.length} lines",
          style: kCategoryStyles["poem"]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentListScreen(title: "Poem", items: content.poem, isFullWordMode: false)),
          ),
        ),
        const SizedBox(height: 12),
        CategoryCard(
          title: "Story",
          subtitle: "${content.story.length} jumle",
          style: kCategoryStyles["story"]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentListScreen(title: "Story", items: content.story, isFullWordMode: false)),
          ),
        ),
        const SizedBox(height: 12),
        CategoryCard(
          title: "Fill in the Blanks",
          subtitle: "${content.fillBlanks.length} sawal",
          style: kCategoryStyles["fill_blanks"]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FillBlankListScreen(items: content.fillBlanks)),
          ),
        ),
      ],
    );
  }
}
