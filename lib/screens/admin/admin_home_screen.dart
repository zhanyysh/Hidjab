import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/screens/admin/admin_users_screen.dart';
import 'package:abayka/services/admin_repository.dart';
import 'package:abayka/services/shop_repository.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final ordersAsync = ref.watch(allOrdersStreamProvider);

    final usersCount = usersAsync.asData?.value.length.toString() ?? '...';
    final ordersCount = ordersAsync.asData?.value.length.toString() ?? '...';

    return Column(
      children: [
        // Statistics Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildStatCard('Всего пользователей', usersCount, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Всего заказов', ordersCount, Colors.green),
            ],
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Управление пользователями',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Users List (Expanded to fill remaining space)
        const Expanded(
          child: UsersManagementScreen(), 
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
