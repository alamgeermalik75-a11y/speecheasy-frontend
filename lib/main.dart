import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:untitled1/utils/theme.dart';
import 'package:untitled1/views/screens/libraryscreens1.dart';

import 'controllers/library_controller.dart';
import 'controllers/progress_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryController()),
        ChangeNotifierProvider(create: (_) =>ProgressController()),
      ],
      child: MaterialApp(
        title: 'Urdu Learning',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LibraryScreen(),
      ),
    );

  }
}

