import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/services/shop_repository.dart';
import 'package:abayka/services/admin_repository.dart';
import 'package:abayka/order.dart';

class AdminHistoryScreen extends ConsumerStatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  ConsumerState<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends ConsumerState<AdminHistoryScreen> {
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
      final orders = await ref.read(shopRepositoryProvider).getAllOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Ошибка загрузки заказов: $e')),
        // );
      }
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    try {
      await ref.read(adminRepositoryProvider).acceptOrder(order.id, order.productId, order.quantity);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ принят, количество товара обновлено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await ref.read(shopRepositoryProvider).updateOrderStatus(orderId, status);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Статус обновлен на: $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления статуса: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? const Center(child: Text('Нет заказов'))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final productName = order.product?['name'] ?? 'Неизвестный товар';
                        final isPending = order.status == 'pending';
                        final address = order.address ?? 'Адрес не указан';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: isPending ? Colors.orange[50] : null,
                          child: ListTile(
                            title: Text('Заказ #${order.id.substring(0, 8)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Товар: $productName'),
                                Text('Кол-во: ${order.quantity} | Сумма: \$${order.totalPrice}'),
                                if (order.variantColor != null)
                                  Text('Цвет: ${order.variantColor}, Размер: ${order.variantSize}'),
                                Text('Адрес: $address'),
                                Text('Статус: ${order.status}', style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(order.status))),
                                Text('Дата: ${order.createdAt.toString().split('.')[0]}'),
                              ],
                            ),
                            trailing: isPending
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => _acceptOrder(order),
                                        tooltip: 'Принять',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _updateStatus(order.id, 'rejected'),
                                        tooltip: 'Отклонить',
                                      ),
                                    ],
                                  )
                                : order.status == 'accepted'
                                    ? IconButton(
                                        icon: const Icon(Icons.local_shipping, color: Colors.blue),
                                        onPressed: () => _updateStatus(order.id, 'shipped'),
                                        tooltip: 'Отправить',
                                      )
                                    : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
