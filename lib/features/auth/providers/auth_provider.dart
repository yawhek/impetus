import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._auth, this._ref) : super(const AsyncData(null));

  final FirebaseAuth? _auth;
  final Ref _ref;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final auth = _auth;
    if (auth == null) return;
    state = const AsyncValue.loading();
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    final auth = _auth;
    if (auth == null) return;
    state = const AsyncValue.loading();
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _ref.read(isGuestProvider.notifier).state = false;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInAsGuest() async {
    state = const AsyncValue.loading();
    try {
      await _auth?.signInAnonymously();
    } catch (_) {}
    _ref.read(isGuestProvider.notifier).state = true;
    state = const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    _ref.read(isGuestProvider.notifier).state = false;
    await _auth?.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(firebaseAuthProvider), ref);
});
