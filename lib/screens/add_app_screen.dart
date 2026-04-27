import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_entry.dart';
import '../models/permission_item.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../widgets/risk_badge.dart';
import 'camera_screen.dart';

class AddAppScreen extends StatefulWidget {
  const AddAppScreen({super.key});
  @override
  State<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends State<AddAppScreen> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = 'Social';
  String _riskLevel = 'Medium';
  File? _imageFile;
  bool _loading = false;

  final List<String> _categories = [
    'Social', 'Navigation', 'Productivity', 'Game', 'Banking', 'Shopping', 'Other'
  ];
  final List<String> _risks = ['Low', 'Medium', 'High', 'Critical'];

  final Map<String, bool> _perms = {
    'Camera': false,
    'Microphone': false,
    'Location': false,
    'Contacts': false,
    'Storage': false,
    'Phone': false,
    'Notifications': false,
    'Nearby devices': false,
    'Calendar': false,
  };
  final Map<String, TextEditingController> _reasonCtrls = {
    'Camera': TextEditingController(),
    'Microphone': TextEditingController(),
    'Location': TextEditingController(),
    'Contacts': TextEditingController(),
    'Storage': TextEditingController(),
    'Phone': TextEditingController(),
    'Notifications': TextEditingController(),
    'Nearby devices': TextEditingController(),
    'Calendar': TextEditingController(),
  };

  Future<void> _openCamera() async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result != null) {
      setState(() => _imageFile = result);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an app name')));
      return;
    }
    setState(() => _loading = true);

    String? screenshotPath;
    if (_imageFile != null) {
      screenshotPath = await StorageService.uploadScreenshot(
          _imageFile!, _nameCtrl.text.trim());
    }

    final entry = AppEntry(
      name: _nameCtrl.text.trim(),
      category: _category,
      riskLevel: _riskLevel,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      screenshotUrl: screenshotPath, // local path
      lastAudited: DateFormat('MMM d, yyyy').format(DateTime.now()),
    );

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final appId = await DatabaseService.insertApp(entry, userId);

    final permItems = _perms.entries
        .map((e) => PermissionItem(
              appId: appId,
              permType: e.key,
              granted: e.value,
              reason: _reasonCtrls[e.key]!.text.trim().isEmpty
                  ? null
                  : _reasonCtrls[e.key]!.text.trim(),
            ))
        .toList();
    await DatabaseService.insertPermissions(permItems);

    final savedEntry = entry.copyWith(id: appId);
    await FirestoreService.saveApp(savedEntry);

    await NotificationService.showSaveSuccess(_nameCtrl.text.trim(), _riskLevel);
    if (_riskLevel == 'Critical') {
      await NotificationService.showCriticalAlert(_nameCtrl.text.trim());
    }
    await NotificationService.scheduleMonthlyReminder();

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add app entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App name', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. TikTok', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            const Text('Risk level', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _risks
                  .map((r) => GestureDetector(
                        onTap: () => setState(() => _riskLevel = r),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: _riskLevel == r
                              ? BoxDecoration(
                                  border: Border.all(
                                      color: Colors.blueGrey, width: 2),
                                  borderRadius: BorderRadius.circular(24))
                              : null,
                          child: RiskBadge(r),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Permissions
            const Text('Permissions', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _perms.keys
                    .map((perm) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(perm,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500))),
                                Switch(
                                  value: _perms[perm]!,
                                  onChanged: (v) =>
                                      setState(() => _perms[perm] = v),
                                  activeColor: const Color(0xFF185FA5),
                                ),
                              ]),
                              if (_perms[perm]!)
                                TextField(
                                  controller: _reasonCtrls[perm],
                                  decoration: InputDecoration(
                                    hintText: 'Why does this app need $perm?',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Camera screenshot
            const Text('Screenshot evidence',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _openCamera,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_imageFile!,
                            fit: BoxFit.cover, width: double.infinity))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: Colors.grey, size: 32),
                          SizedBox(height: 8),
                          Text('Tap to open camera',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                              'Photograph your phone settings screen',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notes', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional observations...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF185FA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
