import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:abayka/features/products/domain/product.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

class ProductsRepository {
  final SupabaseClient _supabase;

  ProductsRepository(this._supabase);

  Future<List<Product>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<void> addProduct(Product product) async {
    await _supabase.from('products').insert(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  Future<String> uploadImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'products/$fileName';
    
    await _supabase.storage.from('product-images').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    final imageUrl = _supabase.storage.from('product-images').getPublicUrl(path);
    return imageUrl;
  }
}
