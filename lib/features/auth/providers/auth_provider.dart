import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:impetus/core/ui_constants.dart';

// Provider che fornisce l'istanza di FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Stream provider per ascoltare i cambiamenti di stato dell'autenticazione (es. login/logout)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Provider per lo stato "Ospite" (Locale/Offline)
final isGuestProvider = StateProvider<bool>((ref) => false);

/// Controller dello stato di autenticazione con pattern StateNotifier e AsyncValue.
///
/// Disaccoppia la logica di FirebaseAuth dall'interfaccia utente, offrendo
/// un flusso reattivo per la gestione del login, registrazione, modalità guest e disconnessione.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._auth, this._ref) : super(const AsyncData(null));

  final FirebaseAuth _auth;
  final Ref _ref;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state =
          AsyncError(e.message ?? 'Credenziali non valide', StackTrace.current);
    } catch (e) {
      state = AsyncError(
          'Errore di connessione. Verifica la rete.', StackTrace.current);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(
          e.message ?? 'Errore durante la registrazione', StackTrace.current);
    } catch (e) {
      state = AsyncError(
          'Impossibile completare la registrazione.', StackTrace.current);
    }
  }

  Future<void> signInAsGuest() async {
    state = const AsyncLoading();
    try {
      await _auth.signInAnonymously();
      _ref.read(isGuestProvider.notifier).state = true;
      state = const AsyncData(null);
    } catch (_) {
      // Fallback offline: abilita l'esperienza locale senza connessione cloud obbligatoria
      _ref.read(isGuestProvider.notifier).state = true;
      state = const AsyncData(null);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _auth.signOut();
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('LOGOUT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: const Text('Sei sicuro di voler uscire dal tuo account?',
          style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ANNULLA', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: UIConstants.errorRed),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('ESCI', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirm ?? false) {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
