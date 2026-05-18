class UserProfile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final int totalXp;
  final int currentStreak;
  final DateTime? lastActiveDate;
  final List<String> todayCompleted;
  final List<String> todayUnlocked;
  final List<bool> weekHistory;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.username,
    this.avatarUrl,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.lastActiveDate,
    this.todayCompleted = const [],
    this.todayUnlocked = const [],
    this.weekHistory = const [false, false, false, false, false, false, false],
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalXp: json['total_xp'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      lastActiveDate: json['last_active_date'] != null ? DateTime.parse(json['last_active_date']) : null,
      todayCompleted: List<String>.from(json['today_completed'] ?? []),
      todayUnlocked: List<String>.from(json['today_unlocked'] ?? []),
      weekHistory: List<bool>.from(json['week_history'] ?? [false, false, false, false, false, false, false]),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'total_xp': totalXp,
      'current_streak': currentStreak,
      if (lastActiveDate != null) 'last_active_date': "${lastActiveDate!.year}-${lastActiveDate!.month.toString().padLeft(2,'0')}-${lastActiveDate!.day.toString().padLeft(2,'0')}",
      'today_completed': todayCompleted,
      'today_unlocked': todayUnlocked,
      'week_history': weekHistory,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
