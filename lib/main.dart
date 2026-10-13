import 'dart:convert';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:impetus/core/globals.dart';
import 'package:impetus/core/navigation_provider.dart';
import 'package:impetus/core/services/sync_service.dart';
import 'package:impetus/core/ui_constants.dart';
import 'package:impetus/features/academy/screens/academy_page.dart';
import 'package:impetus/features/auth/providers/auth_provider.dart';
import 'package:impetus/features/auth/screens/login_screen.dart';
import 'package:impetus/features/nutrition/screens/nutrition_page.dart';
import 'package:impetus/features/training/screens/training_page.dart';
import 'package:impetus/firebase_options.dart';
import 'package:path_provider/path_provider.dart';

// Provider per notificare l'avvenuto completamento del boot sync
final syncTriggerProvider = StateProvider<int>((ref) => 0);

// Inizializza lo storage locale Hive con cifratura AES-256.
// La chiave simmetrica è conservata nel Keystore di sistema tramite FlutterSecureStorage.
Future<HiveAesCipher> _initEncryptedHive() async {
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);

  const secureStorage = FlutterSecureStorage();
  var encryptionKeyString = await secureStorage.read(key: 'hive_key');
  if (encryptionKeyString == null) {
    final key = Hive.generateSecureKey();
    encryptionKeyString = base64UrlEncode(key);
    await secureStorage.write(key: 'hive_key', value: encryptionKeyString);
  }

  final key = base64Url.decode(encryptionKeyString);
  return HiveAesCipher(key);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inizializzazione Firebase Core & Analytics (protetta contro duplicate-app)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase già inizializzato o gestito nativamente: $e');
  }

  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (e) {
    debugPrint('Firebase Analytics non disponibile: $e');
  }

  // 2. Inizializzazione Storage Locale (Hive) con Crittografia AES-256 (GDPR Compliant)
  final encryptionCipher = await _initEncryptedHive();

  final openedProfileBox = await Hive.openBox<dynamic>(
    'user_profile',
    encryptionCipher: encryptionCipher,
  );
  final openedHistoryBox = await Hive.openBox<dynamic>(
    'workout_history',
    encryptionCipher: encryptionCipher,
  );

  // 3. Configurazione UI & Blocco Orientamento Verticale (per Computer Vision)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
            padding: const EdgeInsets.symmetric(vertical: 18),
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      next.whenData((user) async {
        if (user != null) {
          await SyncService.fetchAllFromFirestore(
            ref.read(profileBoxProvider),
            ref.read(historyBoxProvider),
          );
          ref.read(syncTriggerProvider.notifier).state++;
        }
      });
    });

    final authState = ref.watch(authStateChangesProvider);
    final isGuest = ref.watch(isGuestProvider);

    if (isGuest) {
      return const MainScreen();
    }

    return authState.when(
      data: (user) => user != null ? const MainScreen() : const LoginScreen(),
      loading: () => const Scaffold(
        backgroundColor: UIConstants.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: UIConstants.primaryCyan),
        ),
      ),
      error: (e, trace) => Scaffold(
        backgroundColor: UIConstants.deepBlack,
        body: Center(
          child: Text('Errore: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final Map<AppTab, Widget> _loadedPages = {};

  Widget _getPage(AppTab tab) {
    if (tab == AppTab.coach) {
      // Per il Coach non utilizziamo cache persistente:
      // appena l'utente cambia schermata il widget viene smontato e le risorse hardware vengono killate
      return const TrainingPage();
    }

    if (_loadedPages.containsKey(tab)) return _loadedPages[tab]!;

    Widget page;
    switch (tab) {
      case AppTab.academy:
        page = const AcademyPage();
      case AppTab.coach:
        page = const TrainingPage();
      case AppTab.health:
        page = const NutritionPage();
    }

    final storagePage = PageStorage(
      bucket: PageStorageBucket(),
      child: page,
    );
    _loadedPages[tab] = storagePage;
    return storagePage;
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(navigationProvider);
    ref.watch(syncTriggerProvider);

    return Scaffold(
      extendBody: true,
      body: _getPage(currentTab),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              selectedItemColor: UIConstants.primaryCyan,
              unselectedItemColor: Colors.grey.shade600,
              currentIndex: currentTab.indexValue,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              showUnselectedLabels: true,
              selectedFontSize: 12,
              onTap: (index) {
                HapticFeedback.mediumImpact();
                ref.read(navigationProvider.notifier).state =
                    AppTab.values[index];
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded),
                  label: 'Academy',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt_rounded),
                  label: 'AI Coach',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  label: 'Nutrizione AI',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
