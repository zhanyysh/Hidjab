import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Check if user is admin (this assumes you have a 'profiles' table or 'role' in user_metadata)
  // For this skeleton, we'll check user_metadata 'role'
  bool get isAdmin {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['role'] == 'admin';
  }
}
