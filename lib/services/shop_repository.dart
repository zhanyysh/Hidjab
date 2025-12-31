import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:abayka/order.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(Supabase.instance.client);
});

class ShopRepository {
  final SupabaseClient _supabase;

  ShopRepository(this._supabase);

  // Place a new order
  Future<void> placeOrder(OrderModel order) async {
    await _supabase.from('orders').insert(order.toMap());
  }

  // Get all orders for admin
  Future<List<OrderModel>> getAllOrders() async {
    final response = await _supabase
        .from('orders')
        .select('*, products(*)')
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => OrderModel.fromMap(e)).toList();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (status == 'accepted') {
      await _supabase.rpc('accept_order', params: {'order_id': orderId});
    } else {
      await _supabase.from('orders').update({'status': status}).eq('id', orderId);
    }
  }

  // Get current user's orders
  Future<List<OrderModel>> getMyOrders() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('orders')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => OrderModel.fromMap(e)).toList();
  }
}
