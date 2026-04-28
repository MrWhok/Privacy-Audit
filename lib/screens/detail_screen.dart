import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_entry.dart';
import '../models/permission_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../widgets/risk_badge.dart';

class DetailScreen extends StatefulWidget {
  final AppEntry entry;
  const DetailScreen({super.key, required this.entry});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late AppEntry _entry;
  List<PermissionItem> _perms = [];
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  final Map<String, TextEditingController> _reasonCtrls = {};
  late String _riskLevel;
  late String _category;
  bool _loading = true;

  final List<String> _categories = [
    'Social', 'Navigation', 'Productivity', 'Game', 'Banking', 'Shopping', 'Other'
  ];
  final List<String> _risks = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _nameCtrl = TextEditingController(text: _entry.name);
    _notesCtrl = TextEditingController(text: _entry.notes ?? '');
    _riskLevel = _entry.riskLevel;
    _category = _entry.category;
    _loadPerms();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _reasonCtrls.values) { c.dispose(); }
    super.dispose();
  }

  void _openFullScreen(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imagePath: path),
      ),
    );
  }

  Future<void> _loadPerms() async {
    final perms = await DatabaseService.getPermissions(_entry.id!);
    for (final p in perms) {
      _reasonCtrls[p.permType] = TextEditingController(text: p.reason ?? '');
    }
    setState(() { _perms = perms; _loading = false; });
  }

  Future<void> _save() async {
    final updated = _entry.copyWith(
      name: _nameCtrl.text.trim(),
      category: _category,
      riskLevel: _riskLevel,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      lastAudited: DateFormat('MMM d, yyyy').format(DateTime.now()),
    );
    for (int i = 0; i < _perms.length; i++) {
      final text = _reasonCtrls[_perms[i].permType]?.text.trim();
      _perms[i] = _perms[i].copyWith(reason: (text == null || text.isEmpty) ? null : text);
    }
    await DatabaseService.updateApp(updated);
    for (final p in _perms) {
      await DatabaseService.updatePermission(p);
    }
    await FirestoreService.saveApp(updated);
    await NotificationService.showUpdateSuccess(updated.name);
    setState(() { _entry = updated; _editing = false; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry updated')));
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry'),
        content: Text('Remove ${_entry.name} from your audit?'),
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
      try {
        await NotificationService.showDeleteSuccess(_entry.name);
        if (_entry.screenshotUrl != null) {
          await StorageService.deleteScreenshot(_entry.screenshotUrl!);
        }
        await FirestoreService.deleteApp(_entry.id!);
        await DatabaseService.deleteApp(_entry.id!);
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_entry.name),
        actions: [
          if (!_editing)
            IconButton(onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_editing) ...[
                          TextField(controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'App name',
                              border: OutlineInputBorder())),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(labelText: 'Category',
                              border: OutlineInputBorder()),
                            items: _categories.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                          const SizedBox(height: 10),
                          const Text('Risk level', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: _risks.map((r) => GestureDetector(
                              onTap: () => setState(() => _riskLevel = r),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: _riskLevel == r
                                    ? BoxDecoration(
                                        border: Border.all(color: Colors.blueGrey, width: 2),
                                        borderRadius: BorderRadius.circular(24))
                                    : null,
                                child: RiskBadge(r),
                              ),
                            )).toList(),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Text(_entry.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              RiskBadge(_entry.riskLevel),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_entry.category,
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Last audited: ${_entry.lastAudited}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Screenshot
                  if (_entry.screenshotUrl != null) ...[
                    const Text('Evidence screenshot',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _openFullScreen(_entry.screenshotUrl!),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _entry.screenshotUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, _) => Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('Image unavailable', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen, color: Colors.white, size: 14),
                                  SizedBox(width: 3),
                                  Text('Tap to expand', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Permissions',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _perms.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No permissions logged.', style: TextStyle(color: Colors.grey)))
                        : Column(
                            children: _perms.asMap().entries.map((entry) {
                              final i = entry.key;
                              final p = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(p.permType,
                                          style: const TextStyle(fontWeight: FontWeight.w500))),
                                        if (_editing)
                                          Switch(
                                            value: p.granted,
                                            onChanged: (v) => setState(() {
                                              _perms[i] = p.copyWith(granted: v);
                                            }),
                                            activeColor: const Color(0xFF185FA5),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: p.granted
                                                  ? const Color(0xFFE24B4A).withOpacity(0.1)
                                                  : const Color(0xFF639922).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(p.granted ? 'Granted' : 'Denied',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: p.granted
                                                    ? const Color(0xFF791F1F)
                                                    : const Color(0xFF27500A),
                                              )),
                                          ),
                                      ],
                                    ),
                                    if (_editing && p.granted) ...[
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _reasonCtrls[p.permType],
                                        decoration: InputDecoration(
                                          hintText: 'Why does this app need ${p.permType}?',
                                          isDense: true,
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                    ] else if (!_editing && p.reason != null && p.reason!.isNotEmpty)
                                      Text(p.reason!,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    if (i < _perms.length - 1)
                                      Divider(color: Colors.grey.shade200, height: 1),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  if (_editing) ...[
                    const Text('Notes', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Any observations...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else if (_entry.notes != null && _entry.notes!.isNotEmpty) ...[
                    const Text('Notes', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(_entry.notes!, style: const TextStyle(fontSize: 14)),
                  ],
                  if (_editing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() { _editing = false; }),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF185FA5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Update'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  const _FullScreenImageViewer({required this.imagePath});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Screenshot', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _resetZoom,
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            tooltip: 'Reset zoom',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformController,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            widget.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, _) => const Center(
              child: Text('Could not load image',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
