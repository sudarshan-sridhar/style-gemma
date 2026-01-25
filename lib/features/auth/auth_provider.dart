import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);

class AuthState {
  final bool loading;
  final String? error;

  const AuthState({this.loading = false, this.error});

  AuthState copyWith({bool? loading, String? error}) {
    return AuthState(loading: loading ?? this.loading, error: error);
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(const AuthState());

  final Ref ref;

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = state.copyWith(loading: false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
