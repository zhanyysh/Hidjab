import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abayka/services/auth_repository.dart';
import 'package:abayka/theme_provider.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  final _addressController = TextEditingController();
  bool _isEditingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    _addressController.text = prefs.getString('user_address') ?? '';
  }

  Future<void> _saveAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_address', _addressController.text);
    setState(() => _isEditingAddress = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final themeMode = ref.watch(themeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
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
          'Настройки',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
          leading: const Icon(Icons.location_on),
          title: const Text('Адрес проживания'),
          subtitle: _isEditingAddress
              ? TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: 'Введите адрес'),
                )
              : Text(_addressController.text.isEmpty
                  ? 'Адрес не указан'
                  : _addressController.text),
          trailing: IconButton(
            icon: Icon(_isEditingAddress ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditingAddress) {
                _saveAddress();
              } else {
                setState(() => _isEditingAddress = true);
              }
            },
          ),
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
