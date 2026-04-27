class AppEntry {
  final int? id;
  final String name;
  final String category;
  final String riskLevel; 
  final String? notes;
  final String? screenshotUrl;
  final String lastAudited;

  AppEntry({
    this.id,
    required this.name,
    required this.category,
    required this.riskLevel,
    this.notes,
    this.screenshotUrl,
    required this.lastAudited,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'risk_level': riskLevel,
      'notes': notes,
      'screenshot_url': screenshotUrl,
      'last_audited': lastAudited,
    };
  }

  factory AppEntry.fromMap(Map<String, dynamic> map) {
    return AppEntry(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      riskLevel: map['risk_level'],
      notes: map['notes'],
      screenshotUrl: map['screenshot_url'],
      lastAudited: map['last_audited'],
    );
  }

  AppEntry copyWith({
    int? id,
    String? name,
    String? category,
    String? riskLevel,
    String? notes,
    String? screenshotUrl,
    String? lastAudited,
  }) {
    return AppEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      riskLevel: riskLevel ?? this.riskLevel,
      notes: notes ?? this.notes,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      lastAudited: lastAudited ?? this.lastAudited,
    );
  }
}
