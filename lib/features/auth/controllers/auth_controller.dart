import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';

// Provides a single shared instance of AuthService to the whole app.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Exposes the live auth state (logged in / out) as a stream provider.
// Screens/routers watch this to decide what to show.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Handles login/register actions and their loading/error state.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signIn(email: email, password: password);
    });
  }

  Future<void> register({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.register(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});