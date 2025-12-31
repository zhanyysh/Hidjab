import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/services/admin_repository.dart';

class AdminActionHistoryScreen extends ConsumerStatefulWidget {
  const AdminActionHistoryScreen({super.key});

  @override
  ConsumerState<AdminActionHistoryScreen> createState() => _AdminActionHistoryScreenState();
}

class _AdminActionHistoryScreenState extends ConsumerState<AdminActionHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await ref.read(adminRepositoryProvider).getLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading logs: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_searchQuery.isEmpty) {
      return _logs;
    }
    return _logs.where((log) {
      final action = log['action'].toString().toLowerCase();
      final details = log['details'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return action.contains(query) || details.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История действий'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredLogs.isEmpty
              ? const Center(child: Text('Ничего не найдено'))
              : ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final action = log['action'];
                    final details = log['details'].toString();
                    final date = DateTime.parse(log['created_at']).toLocal().toString().split('.')[0];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(details),
                            const SizedBox(height: 4),
                            Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
