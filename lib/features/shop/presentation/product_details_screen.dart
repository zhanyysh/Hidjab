import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/features/products/domain/product.dart';
import 'package:abayka/features/shop/data/shop_repository.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  bool _isBuying = false;

  Future<void> _buyProduct() async {
    setState(() => _isBuying = true);
    try {
      await ref.read(shopRepositoryProvider).purchaseProduct(widget.product.id, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful!')),
        );
        Navigator.pop(context); // Go back to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final discountedPrice = product.price * (1 - product.discount / 100);

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: product.imageUrl != null
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          if (product.discount > 0)
                            Text(
                              '\$${product.price}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(product.type)),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty ? product.description : 'No description available.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: product.quantity > 0 && !_isBuying ? _buyProduct : null,
                      child: _isBuying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(product.quantity > 0 ? 'Buy Now' : 'Out of Stock'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
