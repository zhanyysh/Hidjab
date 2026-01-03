import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/services/admin_repository.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  
  @override
  Widget build(BuildContext context) {
    // Listen to logs stream to auto-refresh users list when actions happen
    ref.listen(adminLogsStreamProvider, (previous, next) {
      if (next.hasValue) {
        // When a new log appears (action performed), refresh the users list
        ref.invalidate(usersProvider);
      }
    });

    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('Нет пользователей'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(usersProvider),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final id = user['id'] as String;
              final email = user['email'] as String? ?? 'Нет Email';
              final rawMetaData = user['raw_user_meta_data'] as Map<String, dynamic>?;
              final role = rawMetaData?['role'] as String? ?? 'user';
              final bannedUntil = user['banned_until'] as String?;
              final isBanned = bannedUntil != null && DateTime.parse(bannedUntil).isAfter(DateTime.now());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role == 'admin' ? Colors.red : Colors.blue,
                    child: Icon(
                      role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(email),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Роль: $role'),
                      if (isBanned)
                        const Text(
                          'ЗАБЛОКИРОВАН',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'role':
                          _updateRole(id, role);
                          break;
                        case 'ban':
                          _toggleBan(id, isBanned);
                          break;
                        case 'delete':
                          _deleteUser(id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'role',
                        child: Text(role == 'admin' ? 'Сделать пользователем' : 'Сделать админом'),
                      ),
                      PopupMenuItem(
                        value: 'ban',
                        child: Text(isBanned ? 'Разблокировать' : 'Заблокировать'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить пользователя', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Future<void> _updateRole(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      await ref.read(adminRepositoryProvider).updateUserRole(userId, newRole);
      ref.invalidate(usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Роль обновлена на $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления роли: $e')),
        );
      }
    }
  }

  Future<void> _toggleBan(String userId, bool isBanned) async {
    try {
      await ref.read(adminRepositoryProvider).toggleUserBan(userId, !isBanned);
      ref.invalidate(usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isBanned ? 'Пользователь разблокирован' : 'Пользователь заблокирован')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка изменения статуса блокировки: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить пользователя'),
        content: const Text('Вы уверены, что хотите удалить этого пользователя? Это действие нельзя отменить.'),
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
        await ref.read(adminRepositoryProvider).deleteUser(userId);
        ref.invalidate(usersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пользователь удален')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления пользователя: $e')),
          );
        }
      }
    }
  }
}
