import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:abayka/services/products_repository.dart';
import 'package:abayka/product.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар'),
        content: const Text('Вы уверены, что хотите удалить этот товар?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(productsRepositoryProvider).deleteProduct(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Товар удален')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при удалении товара: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDiscountDialog(Product product) async {
    final controller = TextEditingController(text: product.discount.toString());
    final newDiscount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установить скидку'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Скидка (%)', suffixText: '%'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) Navigator.pop(context, val);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newDiscount != null) {
      try {
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          description: product.description,
          type: product.type,
          quantity: product.quantity,
          price: product.price,
          originalPrice: product.originalPrice,
          discount: newDiscount,
          imageUrls: product.imageUrls,
          variants: product.variants,
        );
        await ref.read(productsRepositoryProvider).updateProduct(updatedProduct);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Скидка обновлена')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка обновления скидки: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Товары')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/products/add'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Поиск товаров',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final query = _searchController.text.toLowerCase();
                final filteredProducts = products.where((product) {
                  return product.name.toLowerCase().contains(query) ||
                      product.type.toLowerCase().contains(query);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('Нет товаров'));
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final profit = product.price - product.originalPrice;
                    final isOutOfStock = product.quantity <= 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: isOutOfStock ? Colors.red[50] : null,
                      child: ListTile(
                        onTap: () => context.push('/admin/products/add', extra: product),
                        leading: product.imageUrls.isNotEmpty
                            ? Image.network(product.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 50),
                        title: Text(
                          product.name,
                          style: TextStyle(
                            decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Цена: ${product.price} (Прибыль: $profit)'),
                            Text('Скидка: ${product.discount}%'),
                            Text('Вариантов: ${product.variants.length} | Всего шт: ${product.quantity}'),
                            if (isOutOfStock)
                              const Text(
                                'НЕТ В НАЛИЧИИ',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.discount, color: Colors.orange),
                              onPressed: () => _showDiscountDialog(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}