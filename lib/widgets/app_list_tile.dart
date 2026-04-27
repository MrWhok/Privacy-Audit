import 'package:flutter/material.dart';
import '../models/app_entry.dart';
import 'risk_badge.dart';

class AppListTile extends StatelessWidget {
  final AppEntry entry;
  final List<String> grantedPerms;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AppListTile({
    super.key,
    required this.entry,
    required this.grantedPerms,
    required this.onTap,
    required this.onDelete,
  });

  Color _dotColor() {
    switch (entry.riskLevel) {
      case 'Critical': return const Color(0xFFE24B4A);
      case 'High':     return const Color(0xFFEF9F27);
      case 'Medium':   return const Color(0xFF378ADD);
      default:         return const Color(0xFF639922);
    }
  }

  IconData _permIcon(String perm) {
    switch (perm) {
      case 'Camera':         return Icons.camera_alt_outlined;
      case 'Microphone':     return Icons.mic_outlined;
      case 'Location':       return Icons.location_on_outlined;
      case 'Contacts':       return Icons.contacts_outlined;
      case 'Storage':        return Icons.folder_outlined;
      case 'Phone':          return Icons.phone_outlined;
      case 'Notifications':  return Icons.notifications_outlined;
      case 'Nearby devices': return Icons.bluetooth_outlined;
      case 'Calendar':       return Icons.calendar_today_outlined;
      default:               return Icons.lock_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: _dotColor().withOpacity(0.15),
              child: Text(
                entry.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: _dotColor(), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(entry.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      RiskBadge(entry.riskLevel),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(entry.category,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (grantedPerms.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: grantedPerms.map((perm) => Tooltip(
                        message: perm,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE24B4A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(_permIcon(perm), size: 14, color: const Color(0xFFE24B4A)),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
