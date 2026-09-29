import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/library_controller.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/theme.dart';
import '../widgets/alphabetgriditem.dart';
import '../widgets/error_state_view.dart';
import 'sounddetailscreens3.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryController>().loadAlphabets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Consumer<LibraryController>(
        builder: (context, controller, _) {
          if (controller.state == LoadState.loading || controller.state == LoadState.idle) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.state == LoadState.error) {
            return ErrorStateView(
              message: controller.errorMessage ?? '',
              onRetry: () => controller.loadAlphabets(),
            );
          }

          final filtered = controller.alphabets.where((a) {
            if (_query.isEmpty) return true;
            return a.letter.contains(_query) || a.name.toLowerCase().contains(_query.toLowerCase());
          }).toList();

          return Padding(
            padding: r.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urdu Pronunciation Practice',
                  style: TextStyle(
                    fontSize: r.font(13),
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: r.space(4)),
                Text(
                  'Choose a sound to practice',
                  style: TextStyle(
                    fontSize: r.font(20),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: r.space(16)),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search sounds or exercises',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                    ),
                  ),
                ),
                SizedBox(height: r.space(16)),
                Text('All sounds', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: r.space(10)),
                Expanded(
                  child: GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: r.gridColumns(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final alphabet = filtered[index];
                      return AlphabetGridItem(
                        alphabet: alphabet,
                        unresolved: controller.letterLooksUnresolved(alphabet),
                        onRetry: () => controller.retryOne(alphabet.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SoundDetailScreen(alphabet: alphabet),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
