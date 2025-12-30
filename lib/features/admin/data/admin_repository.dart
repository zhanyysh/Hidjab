import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // Fetch all users via RPC
  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _supabase.rpc('get_all_users');
    return List<Map<String, dynamic>>.from(response);
  }

  // Update user role via RPC
  Future<void> updateUserRole(String userId, String role) async {
    await _supabase.rpc('set_user_role', params: {
      'target_user_id': userId,
      'new_role': role,
    });
  }

  // Ban/Unban user via RPC
  Future<void> toggleUserBan(String userId, bool ban) async {
    await _supabase.rpc('toggle_user_ban', params: {
      'target_user_id': userId,
      'should_ban': ban,
    });
  }

  // Delete user via RPC
  Future<void> deleteUser(String userId) async {
    await _supabase.rpc('delete_user_by_admin', params: {
      'target_user_id': userId,
    });
  }
}
