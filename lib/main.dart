import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'repositories/firestore_habit_repository.dart';
import 'repositories/habit_repository.dart';
import 'repositories/memory_habit_repository.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'state/app_mode.dart';
import 'state/habit_store.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final tema = await ThemeController.load();
  final notifikasi = NotificationService();
  await notifikasi.init();

  HabitRepository repo;
  var demo = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    repo = FirestoreHabitRepository();
  } catch (e) {
    debugPrint('Memakai mode demo: $e');
    repo = MemoryHabitRepository.demo();
    demo = true;
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>.value(value: tema),
      Provider<AppMode>.value(value: AppMode(demo: demo)),
      ChangeNotifierProvider<HabitStore>(
          create: (_) => HabitStore(repo, notifikasi)),
    ],
    child: const OnionStreakApp(),
  ));
}

class OnionStreakApp extends StatelessWidget {
  const OnionStreakApp({super.key});

  static const Color _benih = Color(0xFF7B3F8C);

  ThemeData _tema(Brightness b) {
    final skema = ColorScheme.fromSeed(seedColor: _benih, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: skema,
      scaffoldBackgroundColor:
          b == Brightness.light ? const Color(0xFFFFF8F0) : const Color(0xFF1E1A22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeController>().mode;
    return MaterialApp(
      title: 'OnionStreak',
      debugShowCheckedModeBanner: false,
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      themeMode: mode,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
