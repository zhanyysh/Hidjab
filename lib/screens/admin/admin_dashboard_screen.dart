import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:abayka/screens/admin/admin_history_screen.dart';
import 'package:abayka/screens/admin/admin_products_screen.dart';
import 'package:abayka/screens/admin/admin_home_screen.dart';
import 'package:abayka/screens/user/user_home_screen.dart';
import 'package:abayka/screens/admin/admin_settings_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 2; // Default to Main/Home

  final List<Widget> _screens = const [
    AdminHistoryScreen(),
    AdminProductsScreen(),
    AdminHomeScreen(),
    UserHomeScreen(),
    AdminSettingsScreen(),
  ];

  final List<String> _titles = const [
    'Заказы',
    'Управление товарами',
    'Главная',
    'Рынок',
    'Настройки',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 1 // Products tab
          ? FloatingActionButton(
              onPressed: () => context.push('/admin/products/add'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Товары',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Рынок',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
