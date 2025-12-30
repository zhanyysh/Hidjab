import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(Supabase.instance.client);
});

class ShopRepository {
  final SupabaseClient _supabase;

  ShopRepository(this._supabase);

  // Call RPC to purchase product safely (transaction)
  Future<void> purchaseProduct(String productId, int quantity) async {
    await _supabase.rpc('purchase_product', params: {
      'p_product_id': productId,
      'p_quantity': quantity,
    });
  }

  // Get current user's orders
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final response = await _supabase
        .from('orders')
        .select('*, products(*)')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
}
