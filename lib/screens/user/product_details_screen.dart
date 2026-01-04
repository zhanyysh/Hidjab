import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:abayka/product.dart';
import 'package:abayka/order.dart';
import 'package:abayka/services/shop_repository.dart';
import 'package:abayka/services/products_repository.dart';
import 'package:abayka/services/cart_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  bool _isBuying = false;
  ProductVariant? _selectedVariant;
  int _quantity = 1;

  void _addToCart(Product product) {
    if (product.variants.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите вариант (цвет/размер)')),
      );
      return;
    }

    ref.read(cartProvider.notifier).addToCart(
          product,
          color: _selectedVariant?.color,
          size: _selectedVariant?.size,
          quantity: _quantity,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Товар добавлен в корзину')),
    );
  }

  Future<void> _buyProduct(Product product) async {
    if (product.variants.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите вариант (цвет/размер)')),
      );
      return;
    }

    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар закончился')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('user_address') ?? '';
    double? lat = prefs.getDouble('user_lat');
    double? lng = prefs.getDouble('user_lng');
    final addressController = TextEditingController(text: savedAddress);

    final shouldBuy = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoadingLocation = false;

          Future<void> getCurrentLocation() async {
            setState(() => isLoadingLocation = true);
            try {
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied) return;
              }
              if (permission == LocationPermission.deniedForever) return;

              final position = await Geolocator.getCurrentPosition();
              setState(() {
                lat = position.latitude;
                lng = position.longitude;
              });
            } catch (e) {
              // ignore
            } finally {
              setState(() => isLoadingLocation = false);
            }
          }

          return AlertDialog(
            title: const Text('Оформление заказа'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Адрес доставки (комментарий)',
                    hintText: 'Введите ваш адрес',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                if (lat != null && lng != null)
                  Text('Геопозиция: ${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: isLoadingLocation ? null : getCurrentLocation,
                  icon: isLoadingLocation 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.my_location),
                  label: Text(lat != null ? 'Обновить геопозицию' : 'Добавить геопозицию'),
                ),
                if (savedAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Использован сохраненный адрес',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (addressController.text.isEmpty && (lat == null || lng == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Введите адрес или укажите геопозицию')),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Купить'),
              ),
            ],
          );
        }
      ),
    );

    if (shouldBuy != true) return;

    setState(() => _isBuying = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final discountedPrice = product.price * (1 - product.discount / 100);
      
      final order = OrderModel(
        id: '', // Generated by DB
        userId: userId,
        productId: product.id,
        quantity: _quantity,
        totalPrice: discountedPrice * _quantity,
        status: 'pending',
        createdAt: DateTime.now(),
        variantColor: _selectedVariant?.color,
        variantSize: _selectedVariant?.size,
        address: addressController.text,
        locationLat: lat,
        locationLng: lng,
      );

      await ref.read(shopRepositoryProvider).placeOrder(order);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ отправлен! Ожидайте подтверждения.')),
        );
        Navigator.pop(context); // Go back to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка заказа: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productStreamProvider(widget.product.id));

    return productAsync.when(
      data: (product) {
        final discountedPrice = product.price * (1 - product.discount / 100);

        return Scaffold(
          appBar: AppBar(title: Text(product.name)),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: product.imageUrls.isNotEmpty
                      ? PageView.builder(
                          itemCount: product.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              product.imageUrls[index],
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 100, color: Colors.grey),
                        ),
                ),
                if (product.imageUrls.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      product.imageUrls.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                      ),
                    ),
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
                        'Описание',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isNotEmpty ? product.description : 'Нет описания.',
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      if (product.variants.isNotEmpty) ...[
                        const Text(
                          'Выберите вариант:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: product.variants.map((variant) {
                            final isSelected = _selectedVariant == variant;
                            return ChoiceChip(
                              label: Text('${variant.color} - ${variant.size} (${variant.quantity} шт.)'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedVariant = selected ? variant : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          const Text('Количество:', style: TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          ),
                          Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _addToCart(product),
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text('В корзину'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isBuying ? null : () => _buyProduct(product),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: _isBuying
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Заказать'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
