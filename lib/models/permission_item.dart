class PermissionItem {
  final int? id;
  final int appId;
  final String permType; 
  final bool granted;
  final String? reason;

  PermissionItem({
    this.id,
    required this.appId,
    required this.permType,
    required this.granted,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_id': appId,
      'perm_type': permType,
      'granted': granted ? 1 : 0,
      'reason': reason,
    };
  }

  factory PermissionItem.fromMap(Map<String, dynamic> map) {
    return PermissionItem(
      id: map['id'],
      appId: map['app_id'],
      permType: map['perm_type'],
      granted: map['granted'] == 1,
      reason: map['reason'],
    );
  }

  PermissionItem copyWith({bool? granted, String? reason}) {
    return PermissionItem(
      id: id,
      appId: appId,
      permType: permType,
      granted: granted ?? this.granted,
      reason: reason ?? this.reason,
    );
  }
}
