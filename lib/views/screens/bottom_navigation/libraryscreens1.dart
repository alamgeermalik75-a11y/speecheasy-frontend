import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/views/screens/bottom_navigation/bottom_navigation.dart';
import '../../../controllers/library_controller.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/theme.dart';
import '../../widgets/alphabetgriditem.dart';
import '../../widgets/error_state_view.dart';
import '../sounddetailscreens3.dart';

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
      backgroundColor: Color(0xFFFBF9F5),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize:  Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AppBar(
              scrolledUnderElevation: 0,
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> BottomNavigation()));
                  },
                  child: Container(
                    child:  Icon(
                      Icons.keyboard_backspace_sharp,
                      color: Colors.black,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFBAB49B).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              title: Text('Library', style: GoogleFonts.poppins(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold
              ),)
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<LibraryController>(
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
                  SizedBox(height: r.space(4)),
                  Text(
                    'Choose a sound to practice',
                    style: GoogleFonts.poppins(
                      fontSize: r.font(17),
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: r.space(16)),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search sounds or exercises',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      filled: true,
                      fillColor:  Color(0xFFF4F1EC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                      ),
                    ),
                  ),
                  SizedBox(height: r.space(16)),
                  Text('All sounds', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
                  SizedBox(height: r.space(10)),
                  Expanded(
                    child: GridView.builder(
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        // childAspectRatio: 0.9,
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
      ),
    );
  }
}
