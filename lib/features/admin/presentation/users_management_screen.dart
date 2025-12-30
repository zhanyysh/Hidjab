import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/features/admin/data/admin_repository.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ref.read(adminRepositoryProvider).getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _updateRole(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      await ref.read(adminRepositoryProvider).updateUserRole(userId, newRole);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  Future<void> _toggleBan(String userId, bool isBanned) async {
    try {
      await ref.read(adminRepositoryProvider).toggleUserBan(userId, !isBanned);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isBanned ? 'User unbanned' : 'User banned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling ban: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminRepositoryProvider).deleteUser(userId);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final id = user['id'] as String;
                final email = user['email'] as String? ?? 'No Email';
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
                        Text('Role: $role'),
                        if (isBanned)
                          const Text(
                            'BANNED',
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
                          child: Text(role == 'admin' ? 'Demote to User' : 'Promote to Admin'),
                        ),
                        PopupMenuItem(
                          value: 'ban',
                          child: Text(isBanned ? 'Unban User' : 'Ban User'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete User', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
