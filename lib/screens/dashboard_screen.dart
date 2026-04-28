import 'package:flutter/material.dart';
import '../models/app_entry.dart';
import '../models/permission_item.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/app_list_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_app_screen.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<AppEntry> _apps = [];
  Map<String, int> _counts = {'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0};
  String _filterPerm = 'All';
  Map<int, List<PermissionItem>> _permMap = {};
  bool _loading = true;

  static const _permFilters = [
    'All', 'Camera', 'Microphone', 'Location', 'Contacts',
    'Storage', 'Phone', 'Notifications', 'Nearby devices', 'Calendar',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final apps = await DatabaseService.getAllApps(userId);
    final counts = await DatabaseService.getRiskCounts(userId);
    final permMap = <int, List<PermissionItem>>{};
    for (final app in apps) {
      permMap[app.id!] = await DatabaseService.getPermissions(app.id!);
    }
    setState(() {
      _apps = apps;
      _counts = counts;
      _permMap = permMap;
      _loading = false;
    });
  }

  List<AppEntry> get _filtered {
    if (_filterPerm == 'All') return _apps;
    return _apps.where((app) {
      final perms = _permMap[app.id!] ?? [];
      return perms.any((p) => p.permType == _filterPerm && p.granted);
    }).toList();
  }

  int _permCount(String perm) {
    if (perm == 'All') return _apps.length;
    return _apps.where((app) {
      final perms = _permMap[app.id!] ?? [];
      return perms.any((p) => p.permType == perm && p.granted);
    }).length;
  }

  Future<void> _delete(AppEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry'),
        content: Text('Remove ${entry.name} from your audit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.deleteApp(entry.id!);
      _load();
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My audit', style: TextStyle(fontWeight: FontWeight.w500)),
            Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_apps.length} apps tracked',
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          // Risk summary cards
                          Row(children: [
                            _MetricCard(label: 'Critical', count: _counts['Critical']!, color: const Color(0xFFE24B4A)),
                            const SizedBox(width: 8),
                            _MetricCard(label: 'High', count: _counts['High']!, color: const Color(0xFFBA7517)),
                            const SizedBox(width: 8),
                            _MetricCard(label: 'Medium', count: _counts['Medium']!, color: const Color(0xFF185FA5)),
                            const SizedBox(width: 8),
                            _MetricCard(label: 'Low', count: _counts['Low']!, color: const Color(0xFF3B6D11)),
                          ]),
                          const SizedBox(height: 16),
                          // Permission filter chips
                          const Text('Filter by permission',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _permFilters.map((perm) {
                                final count = _permCount(perm);
                                final selected = _filterPerm == perm;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(
                                      perm == 'All' ? 'All ($count)' : '$perm ($count)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: selected ? Colors.white : Colors.grey.shade700,
                                      ),
                                    ),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _filterPerm = perm),
                                    selectedColor: const Color(0xFF185FA5),
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    side: BorderSide(
                                      color: selected ? const Color(0xFF185FA5) : Colors.grey.shade300,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (_filterPerm != 'All') ...[
                            const SizedBox(height: 8),
                            Text(
                              '${filtered.length} app${filtered.length == 1 ? '' : 's'} with $_filterPerm granted',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  filtered.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Text(
                              _filterPerm == 'All'
                                  ? 'No apps yet. Tap + to add one.'
                                  : 'No apps have $_filterPerm granted.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final app = filtered[i];
                              final perms = _permMap[app.id!] ?? [];
                              final grantedPerms = perms.where((p) => p.granted).map((p) => p.permType).toList();
                              return AppListTile(
                                entry: app,
                                grantedPerms: grantedPerms,
                                onTap: () async {
                                  await Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => DetailScreen(entry: app)));
                                  _load();
                                },
                                onDelete: () => _delete(app),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAppScreen()));
          _load();
        },
        backgroundColor: const Color(0xFF185FA5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _MetricCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
