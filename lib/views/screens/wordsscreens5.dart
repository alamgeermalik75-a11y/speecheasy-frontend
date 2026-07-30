import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/words_controller.dart';
import '../../models/alphabet.dart';
import '../../models/word_item.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../widgets/error_state_view.dart';
import 'wordpracticescreens4.dart';

class WordsScreen extends StatefulWidget {
  final Alphabet alphabet;
  const WordsScreen({super.key, required this.alphabet});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  late final WordsController _controller;
  WordPosition? _expanded;

  @override
  void initState() {
    super.initState();
    _controller = WordsController();
    _controller.load(widget.alphabet.name, widget.alphabet.letter);
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(title: Text('${widget.alphabet.letter} Words')),
        body: Consumer<WordsController>(
          builder: (context, controller, _) {
            if (controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error != null) {
              return ErrorStateView(
                message: controller.error!,
                onRetry: () => controller.load(widget.alphabet.name, widget.alphabet.letter),
              );
            }
            return Padding(
              padding: r.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORD POSITION',
                      style: TextStyle(fontSize: r.font(12), color: AppColors.textMuted, letterSpacing: 1)),
                  SizedBox(height: r.space(10)),
                  Expanded(
                    child: ListView(
                      children: WordPosition.values.map((pos) {
                        final words = controller.words?[pos] ?? [];
                        return _PositionCard(
                          position: pos,
                          words: words,
                          expanded: _expanded == pos,
                          onExpandToggle: () => setState(() => _expanded = _expanded == pos ? null : pos),
                          onWordTap: (word) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WordPracticeScreen(
                                  alphabet: widget.alphabet,
                                  words: words,
                                  startIndex: words.indexOf(word),
                                  level: PracticeLevel.words,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final WordPosition position;
  final List<WordItem> words;
  final bool expanded;
  final VoidCallback onExpandToggle;
  final void Function(WordItem) onWordTap;

  const _PositionCard({
    required this.position,
    required this.words,
    required this.expanded,
    required this.onExpandToggle,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            onTap: words.isEmpty ? null : onExpandToggle,
            leading: CircleAvatar(
              backgroundColor: AppColors.lightGreenBg,
              child: Text('${words.length}', style: const TextStyle(fontSize: 10)),
            ),
            title: Text(position.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(words.isEmpty ? 'No words available for this position yet' : position.hint),
            trailing: words.isEmpty
                ? null
                : Icon(expanded ? Icons.expand_less : Icons.chevron_right),
          ),
          if (expanded)
            ...words.map((w) => ListTile(
                  title: Text(w.text, textDirection: TextDirection.rtl),
                  trailing: const Icon(Icons.play_arrow, size: 20),
                  onTap: () => onWordTap(w),
                )),
          if (expanded && words.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => onWordTap(words.first),
                child: Text('Continue with ${position.label}'),
              ),
            ),
        ],
      ),
    );
  }
}
