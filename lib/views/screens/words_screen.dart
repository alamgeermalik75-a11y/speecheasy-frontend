import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/words_controller.dart';
import '../../models/alphabet.dart';
import '../../models/word_item.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../widgets/error_state_view.dart';
import 'word_practice_screen.dart';

class WordsScreen extends StatefulWidget {
  final Alphabet alphabet;
  const WordsScreen({super.key, required this.alphabet});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  late final WordsController _controller;
  WordPosition selectedPosition = WordPosition.initial;
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
       backgroundColor: Color(0xFFFBF9F5),
        appBar: PreferredSize(
          preferredSize:  Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: AppBar(
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: InkWell(
                    onTap: (){
                      Navigator.pop(context);
                    },
                    child: Container(
                      child: Icon(Icons.keyboard_backspace_sharp, color: Colors.black,),
                      decoration: BoxDecoration(
                          color: Color(0xFFBAB49B).withOpacity(0.2),
                          shape: BoxShape.circle
                      ),
                    ),
                  ),
                ),
                title: Text('Words ${widget.alphabet.letter}', style: GoogleFonts.poppins(color: Colors.black),)),
          ),
        ),
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
            final words = controller.words?[selectedPosition] ?? [];
            return Padding(
              padding: r.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORD POSITION',
                      style: GoogleFonts.poppins(fontSize: r.font(15), color: Colors.black, letterSpacing: 1, fontWeight: FontWeight.w500)),
                  SizedBox(height: r.space(10)),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E4DA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: WordPosition.values.map((pos) {
                        final selected = selectedPosition == pos;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPosition = pos;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  pos.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 20,),
                  Expanded(
                    child: ListView(
                      children: words.map((word) {
                        return ListTile(
                          title: Text(
                            word.text,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.gulzar(fontSize: 20),
                          ),
                          trailing: const Icon(
                            Icons.volume_up_outlined,
                            size: 22,
                            color: Colors.black,
                          ),
                          onTap: () {
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

// class _PositionCard extends StatelessWidget {
//   final WordPosition position;
//   final List<WordItem> words;
//   final bool expanded;
//   final VoidCallback onExpandToggle;
//   final void Function(WordItem) onWordTap;
//
//   const _PositionCard({
//     required this.position,
//     required this.words,
//     required this.expanded,
//     required this.onExpandToggle,
//     required this.onWordTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final hasWords = words.isNotEmpty;
//     return Card(
//       margin: const EdgeInsets.only(bottom: 10),
//       child: Column(
//         children: [
//           ListTile(
//             onTap: hasWords ? onExpandToggle : null,
//             leading: Container(
//               width: 40,
//               height: 40,
//               decoration: const BoxDecoration(color: AppColors.lightGreenBg, shape: BoxShape.circle),
//               alignment: Alignment.center,
//               child: Text(
//                 '${words.length}',
//                 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentGreen),
//               ),
//             ),
//             title: Text(position.label, style: const TextStyle(fontWeight: FontWeight.w700)),
//             subtitle: Text(
//               hasWords ? position.hint : 'No words available for this position yet',
//               style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
//             ),
//             trailing: hasWords
//                 ? Icon(
//                     expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
//                     color: AppColors.textMuted,
//                   )
//                 : null,
//           ),
//           if (expanded)
//             ...words.map((w) => ListTile(
//                   title: Text(w.text, textDirection: TextDirection.rtl),
//                   trailing: const Icon(Icons.play_circle_outline_rounded, size: 22, color: AppColors.primaryDark),
//                   onTap: () => onWordTap(w),
//                 )),
//           if (expanded && words.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//               child: ElevatedButton(
//                 onPressed: () => onWordTap(words.first),
//                 child: Text('Continue with ${position.label}'),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
