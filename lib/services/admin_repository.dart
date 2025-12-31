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
    await logAction('update_role', {'target_user_id': userId, 'new_role': role});
  }

  // Ban/Unban user via RPC
  Future<void> toggleUserBan(String userId, bool ban) async {
    await _supabase.rpc('toggle_user_ban', params: {
      'target_user_id': userId,
      'should_ban': ban,
    });
    await logAction('toggle_ban', {'target_user_id': userId, 'should_ban': ban});
  }

  // Delete user via RPC
  Future<void> deleteUser(String userId) async {
    await _supabase.rpc('delete_user_by_admin', params: {
      'target_user_id': userId,
    });
    await logAction('delete_user', {'target_user_id': userId});
  }

  // Accept order and decrement stock
  Future<void> acceptOrder(String orderId, String productId, int quantity) async {
    try {
      // Try using RPC first
      await _supabase.rpc('accept_order', params: {
        'order_id': orderId,
      });
    } catch (e) {
      // Fallback to client-side logic if RPC fails (e.g. function not defined)
      final productResponse = await _supabase
          .from('products')
          .select('quantity')
          .eq('id', productId)
          .single();
      
      final currentQuantity = productResponse['quantity'] as int;
      
      if (currentQuantity < quantity) {
        throw Exception('Недостаточно товара на складе. Остаток: $currentQuantity');
      }

      await _supabase.from('products').update({
        'quantity': currentQuantity - quantity,
      }).eq('id', productId);

      await _supabase.from('orders').update({
        'status': 'accepted',
      }).eq('id', orderId);
    }
    
    await logAction('accept_order', {'order_id': orderId, 'product_id': productId, 'quantity': quantity});
  }

  // Log admin action
  Future<void> logAction(String action, Map<String, dynamic> details) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('admin_logs').insert({
      'admin_id': user.id,
      'action': action,
      'details': details,
    });
  }

  // Get admin logs
  Future<List<Map<String, dynamic>>> getLogs() async {
    final response = await _supabase
        .from('admin_logs')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
