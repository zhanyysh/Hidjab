import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:abayka/product.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

final productStreamProvider = StreamProvider.family<Product, String>((ref, id) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getProductStream(id);
});

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getProductsStream();
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

  Future<void> updateProduct(Product product) async {
    await _supabase.from('products').update(product.toMap()).eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> imageUrls = [];
    for (var imageFile in imageFiles) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(imageFile)}.jpg';
      final path = 'products/$fileName';
      
      await _supabase.storage.from('product-images').upload(
        path,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _supabase.storage.from('product-images').getPublicUrl(path);
      imageUrls.add(imageUrl);
    }
    return imageUrls;
  }

  Stream<Product> getProductStream(String id) {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((event) => Product.fromMap(event.first));
  }

  Stream<List<Product>> getProductsStream() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((event) => event.map((e) => Product.fromMap(e)).toList());
  }
}
