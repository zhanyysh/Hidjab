import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
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
  double? _lat;
  double? _lng;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    _addressController.text = prefs.getString('user_address') ?? '';
    if (prefs.containsKey('user_lat')) {
      _lat = prefs.getDouble('user_lat');
    }
    if (prefs.containsKey('user_lng')) {
      _lng = prefs.getDouble('user_lng');
    }
    setState(() {});
  }

  Future<void> _saveAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_address', _addressController.text);
    if (_lat != null) await prefs.setDouble('user_lat', _lat!);
    if (_lng != null) await prefs.setDouble('user_lng', _lng!);
    setState(() => _isEditingAddress = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Нет доступа к геолокации')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Геолокация запрещена навсегда')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Геолокация обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditingAddress) ...[
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: 'Введите адрес (кв, этаж)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.my_location),
                  label: Text(_lat != null ? 'Обновить геопозицию' : 'Получить геопозицию'),
                ),
                if (_lat != null && _lng != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Координаты: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
              ] else ...[
                Text(_addressController.text.isEmpty
                    ? 'Адрес не указан'
                    : _addressController.text),
                if (_lat != null && _lng != null)
                  Text('Геопозиция: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
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
