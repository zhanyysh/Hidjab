import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/services/shop_repository.dart';
import 'package:abayka/order.dart';

class UserMainScreen extends ConsumerStatefulWidget {
  const UserMainScreen({super.key});

  @override
  ConsumerState<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends ConsumerState<UserMainScreen> {
  bool _isLoading = true;
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ref.read(shopRepositoryProvider).getMyOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading orders: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('История заказов пуста'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final product = order.product;
                    final productName = product?['name'] ?? 'Неизвестный товар';
                    final price = order.totalPrice;
                    final date = order.createdAt.toLocal().toString().split('.')[0];
                    final status = order.status;

                    Color statusColor;
                    switch (status) {
                      case 'pending':
                        statusColor = Colors.orange;
                        break;
                      case 'accepted':
                        statusColor = Colors.blue;
                        break;
                      case 'shipped':
                        statusColor = Colors.purple;
                        break;
                      case 'completed':
                        statusColor = Colors.green;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(productName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Дата: $date'),
                            Text('Статус: $status', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Text(
                          '\$$price',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
