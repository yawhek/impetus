import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:impetus/core/globals.dart';
import 'package:impetus/core/navigation_provider.dart';
import 'package:impetus/core/ui_constants.dart';
import 'package:path_provider/path_provider.dart';

Future<HiveAesCipher> _initEncryptedHive() async {
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);
  const secureStorage = FlutterSecureStorage();
  final existing = await secureStorage.read(key: 'hive_key');
  if (existing != null) {
    return HiveAesCipher(base64Url.decode(existing));
  }
  final key = Hive.generateSecureKey();
  await secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
  return HiveAesCipher(key);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cipher = await _initEncryptedHive();
  final openedProfileBox =
      await Hive.openBox<dynamic>('user_profile', encryptionCipher: cipher);
  final openedHistoryBox =
      await Hive.openBox<dynamic>('workout_history', encryptionCipher: cipher);

  runApp(
    ProviderScope(
      overrides: [
        profileBoxProvider.overrideWithValue(openedProfileBox),
        historyBoxProvider.overrideWithValue(openedHistoryBox),
      ],
      child: const ImpetusApp(),
    ),
  );
}

class ImpetusApp extends StatelessWidget {
  const ImpetusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMPETUS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: UIConstants.primaryCyan,
        scaffoldBackgroundColor: UIConstants.deepBlack,
        cardColor: UIConstants.cardGrey,
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 8,
            backgroundColor: UIConstants.primaryCyan,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: UIConstants.surfaceGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: UIConstants.primaryCyan),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navigationProvider);
    return Scaffold(
      body: Center(
        child: Text(
          currentTab == AppTab.academy ? 'Modulo Academy' : 'Modulo Coach',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: UIConstants.surfaceGrey,
        selectedItemColor: UIConstants.primaryCyan,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: currentTab.indexValue,
        onTap: (index) {
          ref.read(navigationProvider.notifier).state = AppTab.values[index];
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Academy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Coach',
          ),
        ],
      ),
    );
  }
}
