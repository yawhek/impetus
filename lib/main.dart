import 'dart:convert';
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
import 'package:impetus/features/training/screens/training_page.dart';
import 'package:impetus/firebase_options.dart';
import 'package:path_provider/path_provider.dart';

// Chiave di cifratura Hive salvata nello storage sicuro di sistema
Future<({HiveAesCipher cipher, bool keystoreUnavailableWithExistingData})>
    _initEncryptedHive() async {
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);

  const secureStorage = FlutterSecureStorage();
  try {
    String? encryptionKeyString;
    try {
      encryptionKeyString = await secureStorage.read(key: 'hive_key');
    } catch (e) {
      debugPrint(
        'Errore lettura keystore al cold start ($e), nuovo tentativo tra 150 ms...',
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      encryptionKeyString = await secureStorage.read(key: 'hive_key');
    }

    if (encryptionKeyString != null) {
      try {
        final decodedKey = base64Url.decode(encryptionKeyString);
        if (decodedKey.length == 32) {
          return (
            cipher: HiveAesCipher(decodedKey),
            keystoreUnavailableWithExistingData: false,
          );
        }
        debugPrint(
          'Chiave Hive non valida (${decodedKey.length} byte invece di 32).',
        );
      } on FormatException catch (e) {
        debugPrint('Formato chiave Hive in keystore non valido: $e');
      }
    }

    final hasExistingBoxes = await Hive.boxExists('user_profile') ||
        await Hive.boxExists('workout_history');
    if (hasExistingBoxes) {
      debugPrint(
        'ATTENZIONE: Box .hive locali già presenti ma nessuna chiave valida in keystore; '
        'rigenerazione della chiave.',
      );
    }

    final key = Hive.generateSecureKey();
    await secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
    return (
      cipher: HiveAesCipher(key),
      keystoreUnavailableWithExistingData: false,
    );
  } catch (e) {
    final hasExistingBoxes = await Hive.boxExists('user_profile') ||
        await Hive.boxExists('workout_history');
    if (hasExistingBoxes) {
      // Non sovrascrivere la chiave su keystore se i box esistono già: un errore
      // transitorio del keystore non deve distruggere irreversibilmente i dati cifrati.
      debugPrint(
        'ERRORE CRITICO KEYSTORE: lettura fallita dopo retry ($e) con box .hive esistenti. '
        'La chiave "hive_key" NON viene sovrascritta.',
      );
      return (
        cipher: HiveAesCipher(Hive.generateSecureKey()),
        keystoreUnavailableWithExistingData: true,
      );
    }

    debugPrint('Ripristino chiave Hive dopo errore storage: $e');
    final fallbackKey = Hive.generateSecureKey();
    try {
      await secureStorage.write(
        key: 'hive_key',
        value: base64UrlEncode(fallbackKey),
      );
    } catch (_) {}
    return (
      cipher: HiveAesCipher(fallbackKey),
      keystoreUnavailableWithExistingData: false,
    );
  }
}

Future<Box<dynamic>> _openBoxSafe(
  String name,
  HiveAesCipher cipher, {
  bool preserveExistingOnKeystoreError = false,
}) async {
  if (preserveExistingOnKeystoreError) {
    debugPrint(
      'Apertura archivio temporaneo "${name}_recovery" per preservare "$name.hive".',
    );
    return Hive.openBox<dynamic>('${name}_recovery', encryptionCipher: cipher);
  }

  try {
    return await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    // HiveError estende Error nel package hive: intercettazione necessaria per box corrotti.
    // ignore: avoid_catching_errors
  } on HiveError catch (e) {
    debugPrint(
      'HiveError su box "$name" (archivio corrotto o chiave non valida), '
      'rigenero archivio locale: $e',
    );
    try {
      await Hive.deleteBoxFromDisk(name);
    } catch (deleteError) {
      debugPrint('Impossibile eliminare box "$name" da disco: $deleteError');
    }
    return Hive.openBox<dynamic>(name, encryptionCipher: cipher);
  } catch (e) {
    debugPrint('Errore inatteso apertura box "$name": $e');
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      if (DefaultFirebaseOptions.isConfiguredForCurrentPlatform) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
    }
  } catch (e) {
    debugPrint('Inizializzazione Firebase non attiva (modalità locale): $e');
  }

  if (Firebase.apps.isNotEmpty) {
    try {
      await FirebaseAnalytics.instance.logAppOpen();
    } catch (e) {
      debugPrint('Firebase Analytics non disponibile: $e');
    }
  }

  final hiveInit = await _initEncryptedHive();
  final openedProfileBox = await _openBoxSafe(
    'user_profile',
    hiveInit.cipher,
    preserveExistingOnKeystoreError:
        hiveInit.keystoreUnavailableWithExistingData,
  );
  final openedHistoryBox = await _openBoxSafe(
    'workout_history',
    hiveInit.cipher,
    preserveExistingOnKeystoreError:
        hiveInit.keystoreUnavailableWithExistingData,
  );

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
        if (user == null) return;
        if (user.isAnonymous) {
          ref.read(isGuestProvider.notifier).state = true;
          return;
        }
        await SyncService.fetchAllFromFirestore(
          ref.read(profileBoxProvider),
          ref.read(historyBoxProvider),
        );
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

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navigationProvider);

    return Scaffold(
      extendBody: true,
      body: currentTab == AppTab.academy
          ? const AcademyPage()
          : const TrainingPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: UIConstants.surfaceGrey,
        selectedItemColor: UIConstants.primaryCyan,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: currentTab.indexValue,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          HapticFeedback.mediumImpact();
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
