import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/services/auth_repository.dart';
import 'package:abayka/services/shop_repository.dart';
import 'package:abayka/order.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
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
        // Don't show error if it's just empty or table doesn't exist yet
        debugPrint('Error loading orders: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 50,
          child: Icon(Icons.person, size: 50),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user?.email ?? 'Unknown User',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Мои заказы',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_orders.isEmpty)
          const Center(child: Text('Заказов пока нет'))
        else
          ..._orders.map((order) {
            final product = order.product;
            final productName = product?['name'] ?? 'Неизвестный товар';
            final price = order.totalPrice;
            final date = order.createdAt.toLocal().toString().split('.')[0];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text(productName),
                subtitle: Text('Дата: $date'),
                trailing: Text(
                  '\$$price',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          }),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Выйти'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[100],
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }
}
