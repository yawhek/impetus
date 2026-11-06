import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:impetus/core/navigation_provider.dart';
import 'package:impetus/core/ui_constants.dart';

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FirebaseAuth.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) return Stream<User?>.value(null);
  return auth.authStateChanges();
});

final isGuestProvider = StateProvider<bool>((ref) => false);

String _mapFirebaseAuthError(FirebaseAuthException e, String fallback) {
  switch (e.code) {
    case 'invalid-email':
      return "L'indirizzo email non è valido.";
    case 'user-disabled':
      return 'Questo account è stato disabilitato.';
    case 'user-not-found':
      return 'Nessun account trovato con questa email.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email o password non corretti.';
    case 'email-already-in-use':
      return 'Esiste già un account registrato con questa email.';
    case 'weak-password':
      return 'La password è troppo debole (minimo 6 caratteri).';
    case 'operation-not-allowed':
      return 'Metodo di accesso non abilitato.';
    case 'too-many-requests':
      return 'Troppi tentativi falliti. Riprova tra qualche minuto.';
    case 'network-request-failed':
      return 'Errore di rete. Controlla la connessione Internet.';
    default:
      return fallback;
  }
}

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._auth, this._ref) : super(const AsyncData(null));

  final FirebaseAuth? _auth;
  final Ref _ref;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      state = AsyncError(
        'Servizi cloud non configurati su questo dispositivo. Usa Entra come Ospite.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      state = AsyncError(
        _mapFirebaseAuthError(e, 'Credenziali non valide.'),
        StackTrace.current,
      );
    } catch (_) {
      if (!mounted) return;
      state = AsyncError(
        'Errore di connessione. Verifica la rete.',
        StackTrace.current,
      );
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      state = AsyncError(
        'Registrazione non disponibile senza configurazione Firebase.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      state = AsyncError(
        _mapFirebaseAuthError(e, 'Errore durante la registrazione.'),
        StackTrace.current,
      );
    } catch (_) {
      if (!mounted) return;
      state = AsyncError(
        'Impossibile completare la registrazione.',
        StackTrace.current,
      );
    }
  }

  Future<void> signInAsGuest() async {
    final auth = _auth;
    state = const AsyncLoading();
    try {
      await auth?.signInAnonymously();
    } catch (_) {
      // Fallback locale se l'accesso anonimo remoto non è disponibile
    }
    if (!mounted) return;
    _ref.read(isGuestProvider.notifier).state = true;
    state = const AsyncData(null);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _auth?.signOut();
      if (!mounted) return;
      _ref.read(navigationProvider.notifier).state = AppTab.academy;
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncData(null);
    } catch (e) {
      if (!mounted) return;
      state = AsyncError('Errore durante il logout: $e', StackTrace.current);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(firebaseAuthProvider), ref);
});

Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: UIConstants.surfaceGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'LOGOUT',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Sei sicuro di voler uscire dal tuo account?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ANNULLA', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: UIConstants.errorRed),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('ESCI', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (confirm ?? false) {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
