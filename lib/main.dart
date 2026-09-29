import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled1/services/notification_service.dart';
import 'package:untitled1/utils/theme.dart';
import 'package:untitled1/views/screens/splash_screen.dart';
import 'auth/firebase_options.dart';
import 'controllers/library_controller.dart';
import 'controllers/progress_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Firebase is the auth source of truth. Pass its ID token so Supabase
  // treats the user as authenticated (third-party Firebase integration).
  await Supabase.initialize(
    url: 'https://fwrkrpmqmqxlgvyzrizq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3cmtycG1xbXF4bGd2eXpyaXpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0NzE0MTksImV4cCI6MjEwNjA0NzQxOX0.OA6tgsxbqH7bAqoC9tYfo_KTkkfpxuUysQSr0Tpiy7U',
    accessToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return user.getIdToken();

    },
  );
  if (!kIsWeb) {
    try {
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleDailyReminder(hour: 18, minute: 0);
    } catch (e) {
      print('Error setting up notifications: $e');
    }
  }
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
        onGenerateRoute: (routeSettings) {
          final uri = Uri.tryParse(routeSettings.name ?? '');
          if (uri != null && uri.path.contains('reset-password')) {
            return MaterialPageRoute(
              builder: (_) => const Splash(),
              settings: routeSettings,
            );
          }
          return null;
        },
        home: const Splash(),
      ),
    );
  }
}

