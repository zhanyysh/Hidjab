import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/services/auth_repository.dart';
import 'package:abayka/theme_provider.dart';
import 'package:abayka/screens/admin/admin_action_history_screen.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('Тема оформления'),
          trailing: DropdownButton<ThemeMode>(
            value: themeMode,
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                ref.read(themeProvider.notifier).setTheme(newMode);
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Системная'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Светлая'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Темная'),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('История действий'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminActionHistoryScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Выйти', style: TextStyle(color: Colors.red)),
          onTap: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}
