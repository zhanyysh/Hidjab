import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:abayka/services/shop_repository.dart';
import 'package:abayka/services/admin_repository.dart';
import 'package:abayka/order.dart';

class AdminHistoryScreen extends ConsumerStatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  ConsumerState<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends ConsumerState<AdminHistoryScreen> {
  Future<void> _acceptOrder(OrderModel order) async {
    try {
      await ref.read(adminRepositoryProvider).acceptOrder(order.id, order.productId, order.quantity);
      // Force refresh orders list
      ref.invalidate(allOrdersStreamProvider);
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
      // Force refresh orders list
      ref.invalidate(allOrdersStreamProvider);
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

  Future<void> _deleteOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заказ'),
        content: const Text('Вы уверены, что хотите удалить этот заказ?'),
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
        await ref.read(shopRepositoryProvider).deleteOrder(orderId);
        // Force refresh orders list
        ref.invalidate(allOrdersStreamProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Заказ удален')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления заказа: $e')),
          );
        }
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

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse('https://2gis.kg/bishkek/geo/$lng,$lat');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to google maps if 2gis fails or not installed (though web url should work)
      final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersStreamProvider);

    return Scaffold(
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('Нет заказов'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final productName = order.product?['name'] ?? 'Неизвестный товар';
              final isPending = order.status == 'pending';
              final address = order.address ?? 'Адрес не указан';
              final hasLocation = order.locationLat != null && order.locationLng != null;

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
                      if (hasLocation)
                        InkWell(
                          onTap: () => _openMap(order.locationLat!, order.locationLng!),
                          child: Row(
                            children: [
                              const Icon(Icons.map, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Открыть в 2GIS',
                                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      Text('Статус: ${order.status}', style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(order.status))),
                      Text('Дата: ${order.createdAt.toString().split('.')[0]}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPending) ...[
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
                      if (order.status == 'accepted')
                        IconButton(
                          icon: const Icon(Icons.local_shipping, color: Colors.blue),
                          onPressed: () => _updateStatus(order.id, 'shipped'),
                          tooltip: 'Отправить',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _deleteOrder(order.id),
                        tooltip: 'Удалить',
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
    );
  }
}
